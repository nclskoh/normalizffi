//   Copyright (c)  2014-2017 John Abbott and Anna M. Bigatti
//   Author:  2014-2017 John Abbott and Anna M. Bigatti

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


// Source code for input of polynomials and polynomial expressions

#include "CoCoA/RingElemInput.H"

#include "CoCoA/BigIntOps.H"
#include "CoCoA/BigRatOps.H"
#include "CoCoA/SparsePolyOps-RingElem.H"
#include "CoCoA/SparsePolyRing.H"
#include "CoCoA/error.H"
#include "CoCoA/geobucket.H"
#include "CoCoA/ring.H"
#include "CoCoA/symbol.H"
#include "CoCoA/time.H"

#include <algorithm>
using std::sort;
#include <istream>
using std::istream;
#include <iostream> // just for debugging
#include <map>
using std::map;
#include <sstream>
using std::istringstream;
#include <string>
using std::string;
#include <vector>
using std::vector;

namespace CoCoA
{

  char WhatsNext(std::istream& in)
  { // recognized characters
    in >> std::ws; // skip white spaces
    //    std::cout << " WhatsNext: testing " << char(in.peek()) << std::endl;
    if (in.eof()) return '\0';
    const char ch = in.peek();
    if (isdigit(ch)) return 'd'; // d for digit
    if (isalpha(ch)) return 'a'; // a for alpha
    switch (ch)
    {
    case '+':
    case '-':
    case '*':
    case '/':
    case '^':
    case '(':
    case ')':
      return ch;
    case ';':
    case ',':
      return ch;
    }
    // if (ch == '+') return '+';
    // if (ch == '-') return '-';
    // if (ch == '*') return '*';
    // if (ch == '/') return '/';
    // if (ch == '^') return '^';
    // if (ch == '(') return '(';
    // if (ch == ')') return ')';
    // if (ch == ';') return ';';
    // if (ch == ',') return ',';
    CoCoA_ERROR(string("Illegal char \'")+ch+'\'', "WhatsNext");
    return 'o'; // just to keep compiler quiet
  }


  void CoCoA_ERROR_NextChar(std::istream& in, const string& FuncName)
  {
    in.clear();
    CoCoA_ERROR("Unexpected \'"+ string(1,char(in.peek())) +"\'", FuncName);
  }


  RingElem ReadFactor(const ring& P, std::istream& in, const map<symbol, RingElem>& SymTable)
  {
    symbol s("temp");
    RingElem tmp(P);
    const int base = (in.flags() & std::ios::oct) ? 8 : (in.flags() & std::ios::hex) ? 16 : 10;

    switch ( WhatsNext(in) )
    {
    case 'a':  // letter
      in >> s;  if (!in) CoCoA_ERROR_NextChar(in, "ReadFactor: symbol");
      if (SymTable.find(s) == SymTable.end()) CoCoA_ERROR("symbol not in ring", "ReadFactor: symbol");
      tmp = SymTable.find(s)->second;
      break;
    case 'd':  // digit
    {
      BigInt N;
      in >> N;
      // No need to check status of in, since there was at least 1 digit
      if (in.peek() != '.') { tmp = RingElem(P,N); break; }
      in.ignore(); // skip over "."
      // Next lines copied from BigRat.C
      const string AfterDot = ScanUnsignedIntegerLiteral(in);
      const long NumPlaces = len(AfterDot);
      if (NumPlaces == 0) { tmp = RingElem(P,N); break; }
      istringstream FracDigits(AfterDot);
      if (base == 8) FracDigits >> std::oct;
      if (base == 16) FracDigits >> std::hex;
      BigRat FracPart;
      FracDigits >> FracPart;
      FracPart /= power(base, NumPlaces);
      tmp = RingElem(P, N+FracPart);
      break;
    }
    case '(':
      in.ignore(); // '('
      tmp = ReadExpr(P, in);
      if ( WhatsNext(in) != ')' )  CoCoA_ERROR_NextChar(in, "ReadFactor: ()");
      in.ignore(); // ')'
      break;
    default: CoCoA_ERROR_NextChar(in, "ReadFactor");
    }
    if ( WhatsNext(in) != '^' )  return tmp;
    in.ignore(); // '^'
    // Just read a '^', so expect either a non-negative integer literal or '(' integer-literal ')'
    in >> std::ws;
    const char AfterUpArrow = in.peek();
    if (!in) CoCoA_ERROR_NextChar(in, "ReadFactor: exponent");
    if (AfterUpArrow != '(' && !IsDigitBase(AfterUpArrow, base))
      CoCoA_ERROR_NextChar(in, "ReadFactor: exponent");
    if (AfterUpArrow == '(')
      in.ignore(); // skip over the '('
    BigInt exp;
    in >> exp;
    if (!in)
      CoCoA_ERROR_NextChar(in, "ReadFactor: exponent");
    if (AfterUpArrow == '(')
    {
      // Now check that there was the matching ')'
      // We move past the next char only if it is ')', so that the error message makes sense
      in >> std::ws;
      const char CloseBracket = in.peek();
      if (!in || CloseBracket != ')')
        CoCoA_ERROR_NextChar(in, "ReadFactor: exponent");
      in.ignore();
    }
    return power(tmp, exp);
  }


  RingElem ReadProduct(const ring& P, std::istream& in, const map<symbol, RingElem>& SymTable)
  {
    char w = '*';
    RingElem resProd(one(P));

    while (true)
    {
      if ( w == '*' )  resProd *= ReadFactor(P, in, SymTable);
      else             resProd /= ReadFactor(P, in, SymTable); // ( w == '/' )
      if ( WhatsNext(in) != '*' &&  WhatsNext(in) != '/' )  break;
      // uncomment the following to prevent a/b*c, a/b/c
      // if ( w == '/' ) 
      //   CoCoA_ERROR_NextChar(in, "ReadProduct: ambiguous after \'/\'");
      in >> w; // '*' or '/'
    }
    return resProd;
  }


  //-------- input from istream --------------------

  namespace // anonymous
  {
    
    bool CmpLPP(const RingElem& f1, const RingElem& f2)
    {
      return LPP(f1) < LPP(f2);
    }

    // Faster version if input is a large sum of terms -- uses geobuckets.
    RingElem ReadExprInSparsePolyRing(const ring& P, std::istream& in, const std::map<symbol, RingElem>& SymTable)
    {
      char w = WhatsNext(in);
      geobucket gbk(P);
      // Put single monomials in a vector; later I'll sort them and sum them.
      // This works well if the order of the monomials is different from that of P.
      // JAA 2016-05-18 Still not happy with this solution; a std::list may be better;
      // perhaps use MoveLM instead of += in loop when summing vector entries???
      vector<RingElem> TermList;
      
      while (true)
      {
        if ( w == '-' || w == '+' )  in.ignore(); // '+/-'
        RingElem summand = ReadProduct(P,in, SymTable);
        if ( w == '-' )
          summand = -summand; // inefficient?
        if (IsMonomial(summand))
          TermList.push_back(summand); // SLUG, makes wasteful copy; use MoveLM???
        else
          gbk.myAddClear(summand, NumTerms(summand));
        w = WhatsNext(in);
        if ( (w == ',') || (w == ';') || (w == ')') || (w == '\0') )  break;
        if ( (w != '-') && (w != '+') )  CoCoA_ERROR_NextChar(in, "ReadExpr");
      }
      RingElem ans(P);
      if (!TermList.empty())
      {
        sort(TermList.begin(), TermList.end(), CmpLPP);
        const long nterms = len(TermList);
        for (long i=0; i < nterms; ++i)
          ans += TermList[i];
        if (IsZero(gbk))
          return ans;
        gbk.myAddClear(ans, NumTerms(ans));
      }

      // Get answer out of geobucket -- awkward syntax :-(
      AddClear(ans, gbk);
      return ans;
    }


    RingElem ReadExpr(const ring& P, std::istream& in, const map<symbol, RingElem>& SymTable)
    {
      if (IsSparsePolyRing(P))
        return ReadExprInSparsePolyRing(P, in, SymTable); // usefully faster if input is large sum of terms
      char w = WhatsNext(in);
      RingElem f(P);

      while (true)
      {
        if ( w == '-' || w == '+' )  in.ignore(); // '+/-'
        if ( w == '-' )  f -= ReadProduct(P,in, SymTable);  else  f += ReadProduct(P,in, SymTable);
        w = WhatsNext(in);
        if ( (w == ',') || (w == ';') || (w == ')') || (w == '\0') )  break;
        if ( (w != '-') && (w != '+') )  CoCoA_ERROR_NextChar(in, "ReadExpr");
      }
      return f;
    }


  } // namespace anonymous -------------------------------------------------


  RingElem ReadExpr(const ring& P, std::istream& in)
  {
    const vector<symbol> syms = symbols(P);
    map<symbol, RingElem> SymTable;
    for (int i=0; i < len(syms); ++i)
      SymTable[syms[i]] = RingElem(P, syms[i]);
    return ReadExpr(P, in, SymTable);
  }


  RingElem ReadExprSemicolon(const ring& P, std::istream& in)
  {
    RingElem f = ReadExpr(P, in);
    if ( WhatsNext(in) != ';' )  CoCoA_ERROR_NextChar(in, "ReadExprSemicolon");
    in.ignore(); // ';'
    return f;
  }


  std::vector<RingElem> RingElems(const ring& P, std::istream& in)
  {
    const vector<symbol> syms = symbols(P);
    map<symbol, RingElem> SymTable;
    for (int i=0; i < len(syms); ++i)
      SymTable[syms[i]] = RingElem(P, syms[i]);

    std::vector<RingElem> v;

    char w = 'X';
    while (w != '\0')
    {
      //      std::cout << " WhatsNext: testing " << f << std::endl;
      v.push_back(ReadExpr(P, in, SymTable));
      switch ( w = WhatsNext(in) )
      {
      case '\0':   break;
      case ',':    in.ignore();        continue;
      default:     CoCoA_ERROR_NextChar(in, "RingElems");
      }
    }
    return v;
  }
  

  //-------- input from string --------------------

  RingElem ReadExprSemicolon(const ring& P, const std::string& s)
  {
    istringstream is(s);
    return ReadExprSemicolon(P, is);
  }


  RingElem ReadExpr(const ring& P, const std::string& s)
  {
    istringstream is(s);
    RingElem f = ReadExpr(P, is);
    if (WhatsNext(is) != '\0') CoCoA_ERROR_NextChar(is, "ReadExpr");
    return f;
  }


  std::vector<RingElem> RingElems(const ring& P, const std::string& s)
  {
    istringstream is(s);
    vector<RingElem> v = RingElems(P, is);
    if (WhatsNext(is) != '\0') CoCoA_ERROR_NextChar(is, "RingElems");
    return v;
  }
  

} // end of namespace CoCoA

// RCS header/log in the next few lines
// $Header: /Volumes/Home_1/cocoa/cvs-repository/CoCoALib-0.99/src/AlgebraicCore/RingElemInput.C,v 1.15 2020/02/03 17:06:17 abbott Exp $
// $Log: RingElemInput.C,v $
// Revision 1.15  2020/02/03 17:06:17  abbott
// Summary: Changed if cascade into a switch
//
// Revision 1.14  2019/10/18 14:11:19  bigatti
// -- Renamed ReadExprVector --> RingElems
//
// Revision 1.13  2019/10/09 16:37:36  bigatti
// -- added ReadExprVector
//
// Revision 1.12  2018/05/22 14:16:40  abbott
// Summary: Split BigRat into BigRat (class defn + ctors) and BigRatOps
//
// Revision 1.11  2018/05/18 16:42:11  bigatti
// -- added include SparsePolyOps-RingElem.H
//
// Revision 1.10  2018/05/18 12:15:56  bigatti
// -- renamed IntOperations --> BigIntOps
//
// Revision 1.9  2017/04/26 09:14:41  bigatti
// -- updated Copyright
//
// Revision 1.8  2016/10/08 19:48:16  abbott
// Summary: Two changes: now handles correctly 5/4^3 and 1.25^3; allow exponent to be in ()s
//
// Revision 1.7  2016/07/21 15:13:58  abbott
// Summary: Now reads literals as BigRat (incl. decimal notation) instead of BigInt
//
// Revision 1.6  2016/05/18 12:21:11  abbott
// Summary: Major overhaul for ReadExpr in a poly ring; added SymbolTable & more
//
// Revision 1.5  2016/05/09 20:02:58  abbott
// Summary: Added ReadExprInSparsePolyRing
//
// Revision 1.4  2015/07/28 11:54:46  bigatti
// -- just one comment
//
// Revision 1.3  2014/03/21 15:57:19  bigatti
// -- Ring is now first argument of ReadExpr
//
// Revision 1.2  2014/01/30 16:21:53  bigatti
// -- removed restriction about 1/3*x
//
// Revision 1.1  2014/01/30 15:15:33  bigatti
// -- first import
//
