#ifndef CoCoA_NumTheory_ContFrac_H
#define CoCoA_NumTheory_ContFrac_H

//   Copyright (c)  2009,2012  John Abbott

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
//   -------------------------------------------------------------------------


#include "CoCoA/BigInt.H"
#include "CoCoA/BigRat.H"

#include <iosfwd>
// using std::ostream;


namespace CoCoA
{
  
  class ContFracIter
  {
  public:
    explicit ContFracIter(const BigRat& Q);
    const BigInt& operator*() const;
    ContFracIter& operator++();
    ContFracIter operator++(int);
    friend bool IsEnded(const ContFracIter& CFIter);
    friend bool IsFinal(const ContFracIter& CFIter);
  private: // data members
    BigRat myFrac;
    BigInt myQuot;
    friend std::ostream& operator<<(std::ostream& out, const ContFracIter& CFIter);
  };

  bool IsEnded(const ContFracIter& CFIter);
  bool IsFinal(const ContFracIter& CFIter);

  inline const BigInt& quot(const ContFracIter& CFIter)
  { return *CFIter; }

  //////////////////////////////////////////////////////////////////

  class ContFracApproximant
  {
  public:
    ContFracApproximant();
    void myAppendQuot(const MachineInt& q);
    void myAppendQuot(const BigInt& q);
    const BigRat& myRational() const { return myCurr; }
  private: // data members
    BigRat myCurr; // WARNING: initial value is anomalous, namely 1/0
    BigRat myPrev;
    BigRat myNext; // Just workspace; used only in operator++
    friend std::ostream& operator<<(std::ostream& out, const ContFracApproximant& CFConv);
  };

  std::ostream& operator<<(std::ostream& out, const ContFracApproximant& CFConv);

  //////////////////////////////////////////////////////////////////

  class CFApproximantsIter
  {
  public:
    explicit CFApproximantsIter(const BigRat& Q);
    explicit CFApproximantsIter(const ContFracIter& CFIter);
    const BigRat& operator*() const { return myApproximant.myRational(); }
    CFApproximantsIter& operator++();
    CFApproximantsIter operator++(int);
    friend bool IsEnded(const CFApproximantsIter& CFAIter) { return IsEnded(CFAIter.myCFIter); }
  private: // data members
    ContFracIter myCFIter;
    ContFracApproximant myApproximant;
    friend std::ostream& operator<<(std::ostream& out, const CFApproximantsIter& CFAIter);
  };

  std::ostream& operator<<(std::ostream& out, const ContFracIter& CFIter);
  std::ostream& operator<<(std::ostream& out, const CFApproximantsIter& CFAIter);

  BigRat CFApprox(const BigRat& q, const BigRat& MaxRelErr);


} // end of namespace CoCoA



// RCS header/log in the next few lines
// $Header: /Volumes/Home_1/cocoa/cvs-repository/CoCoALib-0.99/include/CoCoA/NumTheory-ContFrac.H,v 1.1 2019/03/18 11:24:19 abbott Exp $
// $Log: NumTheory-ContFrac.H,v $
// Revision 1.1  2019/03/18 11:24:19  abbott
// Summary: Split NumTheory into several smaller files
//
//

#endif
