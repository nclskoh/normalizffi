//   Copyright (c)  1999,2009-2011  John Abbott

//   This file is part of the source of CoCoALib, the CoCoA Library.

//   CoCoALib is free software: you can redistribute it and/or modify
//   it under the terms of the GNU General Public License as published by
//   the Free Software Foundation, either version 3 of the License, or
//   (at your option) any later version.

//   CoCoALib is distributed in the hope that it will be useful,
//   but WITHOUT ANY WARRANTY; without even the implied warranty of
//   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//   GNU General Public License for more details.

//   You should have received a copy of the GNU General Public License
//   along with CoCoALib.  If not, see <http://www.gnu.org/licenses/>.


#include "CoCoA/NumTheory-ContFrac.H"

#include "CoCoA/BigIntOps.H"
#include "CoCoA/BigRatOps.H"
#include "CoCoA/assert.H"
#include "CoCoA/error.H"

#include <iostream>
using std::ostream;


namespace CoCoA
{

  ContFracIter::ContFracIter(const BigRat& Q)
  {
    myQuot = floor(Q);
    if (!IsOneDen(Q))
      myFrac = 1/(Q - myQuot); // non-negative!
  }

  const BigInt& ContFracIter::operator*() const
  {
    if (IsEnded(*this)) CoCoA_ERROR(ERR::IterEnded, "ContFracIter::operator*");
    return myQuot;
  }

  ContFracIter& ContFracIter::operator++()
  {
    if (IsEnded(*this)) CoCoA_ERROR(ERR::IterEnded, "ContFracIter::operator++");
    myQuot = floor(myFrac);
    if (IsOneDen(myFrac))
      myFrac = 0;
    else
      myFrac = 1/(myFrac - myQuot); // strictly positive!
    return *this;
  }

  ContFracIter ContFracIter::operator++(int)
  {
    ContFracIter prev = *this;
    operator++();
    return prev;
  }


  bool IsEnded(const ContFracIter& CFIter)
  {
    return IsZero(CFIter.myQuot) && IsZero(CFIter.myFrac);
  }


  bool IsFinal(const ContFracIter& CFIter)
  {
    return IsZero(CFIter.myFrac);
  }


  std::ostream& operator<<(std::ostream& out, const ContFracIter& CFIter)
  {
    if (!out) return out;  // short-cut for bad ostreams
    out << "ContFracIter(myFrac = " << CFIter.myFrac
        << ", myQuot = " << CFIter.myQuot << ")";
    return out;
  }


  //////////////////////////////////////////////////////////////////

  ContFracApproximant::ContFracApproximant():
      myCurr(BigRat::OneOverZero), // WARNING: anomalous value, 1/0
      myPrev(0,1)
  {}


  void ContFracApproximant::myAppendQuot(const MachineInt& q)
  {
    // Simple rather than fast.
    myAppendQuot(BigInt(q));
  }

  void ContFracApproximant::myAppendQuot(const BigInt& q)
  {
    // These 9 lines should avoid (all explicit) temporaries:
    // NB I have to use pointers to mpq_t because GMP's design won't let me use references.
    mpq_t* prev = &mpqref(myPrev);
    mpq_t* curr = &mpqref(myCurr);
    mpq_t* next = &mpqref(myNext);
    mpz_mul(mpq_numref(*next), mpq_numref(*curr), mpzref(q));
    mpz_add(mpq_numref(*next), mpq_numref(*next), mpq_numref(*prev));
    mpz_mul(mpq_denref(*next), mpq_denref(*curr), mpzref(q));
    mpz_add(mpq_denref(*next), mpq_denref(*next), mpq_denref(*prev));
    swap(myCurr, myPrev);
    swap(myNext, myCurr);
  }


  std::ostream& operator<<(std::ostream& out, const ContFracApproximant& CFConv)
  {
    if (!out) return out;  // short-cut for bad ostreams
    out << "ContFracApproximant(myCurr = " << CFConv.myCurr
        << ",  myPrev = " << CFConv.myPrev << ")";
    return out;
  }

  //////////////////////////////////////////////////////////////////


  // NB if (Q == 0) then myCFIter starts off "ended"
  CFApproximantsIter::CFApproximantsIter(const BigRat& Q):
      myCFIter(Q),
      myApproximant()
  {
    if (!IsEnded(myCFIter))
      myApproximant.myAppendQuot(quot(myCFIter));
  }

  CFApproximantsIter::CFApproximantsIter(const ContFracIter& CFIter):
      myCFIter(CFIter),
      myApproximant()
  {
    if (!IsEnded(myCFIter))
      myApproximant.myAppendQuot(quot(myCFIter));
  }


  CFApproximantsIter& CFApproximantsIter::operator++()
  {
    if (IsEnded(*this)) CoCoA_ERROR(ERR::IterEnded, "CFApproximantsIter::operator++");
    ++myCFIter;
    if (IsEnded(myCFIter)) return *this;
    myApproximant.myAppendQuot(quot(myCFIter));

    return *this;
  }

  CFApproximantsIter CFApproximantsIter::operator++(int)
  {
    CFApproximantsIter prev = *this;
    operator++();
    return prev;
  }


  std::ostream& operator<<(std::ostream& out, const CFApproximantsIter& CFAIter)
  {
    if (!out) return out;  // short-cut for bad ostreams
    out << "CFApproximantsIter(myApproximant = " << CFAIter.myApproximant
        << ",  myCFIter = " << CFAIter.myCFIter << ")";
    return out;
  }


  // Return first cont frac convergent having rel error at most MaxRelErr
  BigRat CFApprox(const BigRat& q, const BigRat& MaxRelErr)
  {
    // Simple rather than superfast.
    if (MaxRelErr < 0 || MaxRelErr > 1) CoCoA_ERROR(ERR::BadArg, "CFApprox: relative error must be between 0 and 1");
    if (IsZero(q) || IsZero(MaxRelErr)) return q;
    const BigRat MaxAbsErr = abs(q*MaxRelErr);
    if (MaxAbsErr >= 1) return BigRat(floor(q),1);
    CFApproximantsIter CFAIter(q);
    while (abs(q - *CFAIter) > MaxAbsErr)
    {
      ++CFAIter;
    }
    return *CFAIter;
  }


} // end of namespace CoCoA


// RCS header/log in the next few lines
// $Header: /Volumes/Home_1/cocoa/cvs-repository/CoCoALib-0.99/src/AlgebraicCore/NumTheory-ContFrac.C,v 1.2 2020/02/11 16:12:18 abbott Exp $
// $Log: NumTheory-ContFrac.C,v $
// Revision 1.2  2020/02/11 16:12:18  abbott
// Summary: Added some checks for bad ostream (even to mem fns myOutput); see redmine 969
//
// Revision 1.1  2019/03/18 11:24:19  abbott
// Summary: Split NumTheory into several smaller files
//
//
