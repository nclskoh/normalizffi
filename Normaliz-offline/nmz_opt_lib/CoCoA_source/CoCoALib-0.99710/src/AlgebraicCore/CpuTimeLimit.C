//   Copyright (c)  2017,2018  John Abbott,  Anna M. Bigatti

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


#include "CoCoA/CpuTimeLimit.H"
#include "CoCoA/error.H"
#include "CoCoA/time.H"

#include <iostream>
using std::ostream;

namespace CoCoA
{

  //-------------------------------------------------------
  // Must define this because of virtual mem fns.
  TimeoutException::~TimeoutException()
  {}


  void TimeoutException::myOutputSelf(std::ostream& out) const
  {
    if (!out) return;  // short-cut for bad ostreams
    out << "CoCoA::TimeoutException(context=\"" << myContext << "\")";
  }
    
  //------------------------------------------------------------------
  
  CpuTimeLimit::CpuTimeLimit(double interval):
      myCountdown(1),
      myInterval(1),
      myTotalCount(0),
      myRefCount(0),
      myRef2Count(0),
      myRefTime(CpuTime()),
      myRef2Time(myRefTime),
      myTriggerTime(myRefTime+interval),
      myTriggerTimePlusEpsilon(myTriggerTime+interval/16+0.0625),
      myVariability(64)
  {
    if (interval < 0) CoCoA_ERROR(ERR::NotNonNegative, "CpuTimeLimit ctor");
    if (interval > 1000000) CoCoA_ERROR(ERR::ArgTooBig, "CpuTimeLimit ctor");
  }

  
  void CpuTimeLimit::myPrepareForNewLoop(int variability) const
  {
    if (IamUnlimited()) return; // do nothing
    if (variability < 1 or variability > 256) CoCoA_ERROR(ERR::ArgTooBig, "myPrepareForNewLoop");
    myInterval = 1;
    myCountdown = 1;
    myRefCount = myTotalCount;
    myRef2Count = myTotalCount;
    const double now = CpuTime();
    myRefTime = now;
    myRef2Time = now;
    myVariability = variability;
  }

  
  bool CpuTimeLimit::IamTimedOut() const
  {
    if (IamUnlimited()) return false;  // Should (almost) never happen!
    myTotalCount += myInterval;
    const double now = CpuTime();
    if (now > myTriggerTime) return true;
    if (myTotalCount-myRef2Count > 15) { myRefCount = myRef2Count; myRefTime = myRef2Time; myRef2Count = myTotalCount; myRef2Time = now; }
    // Compute ave time per count
    const double AveTime = (now-myRefTime)/(myTotalCount-myRefCount);
    const double TimeToDeadline = myTriggerTimePlusEpsilon - now;
    double EstNextInterval = myVariability*myInterval*AveTime;
//    std::clog<<"myRefCount="<<myRefCount<<"   myRefTime="<<myRefTime<<"   myRef2Count="<<myRef2Count<<"   myRef2Time="<<myRef2Time<<std::endl;
//    std::clog<<"count diff="<<myTotalCount-myRefCount<<"   AveTime="<<AveTime<<"  rem="<<TimeToDeadline<<"   est="<<EstNextInterval<<"   count="<<myInterval<<std::endl;
    if (EstNextInterval < TimeToDeadline/4) { if (myInterval < 65536) { myInterval *= 2; } }
    else if (EstNextInterval > TimeToDeadline)
    {
      while (EstNextInterval > 0.1 && EstNextInterval > TimeToDeadline && myInterval > 1)
      { EstNextInterval /= 2; myInterval /= 2; }
    }
    myCountdown = myInterval;
    return false;
  }


  // Quick makeshift impl.
  std::ostream& operator<<(std::ostream& out, const CpuTimeLimit& TimeLimit)
  {
    if (!out) return out;  // short-cut for bad ostreams
    
    if (IsUnlimited(TimeLimit)) return out << "CpuTimeLimit(UNLIMITED)";

    out << "CpuTimeLimit(TriggerTime=" << TimeLimit.myTriggerTime
        << ", CurrTime=" << CpuTime()
        << ",  Countdown=" << TimeLimit.myCountdown
        << ", interval=" << TimeLimit.myInterval << ")";
    return out;
  }


  // Special ctor for "unlimited" CpuTimeLimit object;
  // called only by NoCpuTimeLimit (below).
  CpuTimeLimit::CpuTimeLimit(NO_LIMIT_t):
      myCountdown(-1),
      myInterval(-1), // negative myInterval marks out the "unlimited" object
      myTotalCount(-1),
      myRefCount(-1),
      myRef2Count(-1),
      myRefTime(-1.0),
      myRef2Time(-1.0),
      myTriggerTime(-1.0),
      myTriggerTimePlusEpsilon(-1.0),
      myVariability(-1)
    {}
  

  const CpuTimeLimit& NoCpuTimeLimit()
  {
    static const CpuTimeLimit SingleCopy(CpuTimeLimit::NO_LIMIT);
    return SingleCopy;
  }


} // end of namespace CoCoA


// RCS header/log in the next few lines
// $Header: /Volumes/Home_1/cocoa/cvs-repository/CoCoALib-0.99/src/AlgebraicCore/CpuTimeLimit.C,v 1.16 2020/02/11 16:56:40 abbott Exp $
// $Log: CpuTimeLimit.C,v $
// Revision 1.16  2020/02/11 16:56:40  abbott
// Summary: Corrected last update (see redmine 969)
//
// Revision 1.15  2020/01/18 21:33:18  abbott
// Summary: Added two checks for being unlimited
//
// Revision 1.14  2019/12/21 16:40:16  abbott
// Summary: Added "variability"; revised myPrepareForNewLoop
//
// Revision 1.13  2019/12/20 15:51:38  abbott
// Summary: Major revision to CpuTimeLimit
//
// Revision 1.12  2019/10/29 11:35:46  abbott
// Summary: Replaced using namespace std by th specific using fn-name directives.
//
// Revision 1.11  2018/06/27 10:20:16  abbott
// Summary: Updated
//
// Revision 1.10  2018/06/27 09:37:57  abbott
// Summary: More detailed printout (more helpful for debugging)
//
// Revision 1.9  2018/06/25 12:31:49  abbott
// Summary: Added overflow protection when increasing interval length
//
// Revision 1.8  2018/05/25 09:24:46  abbott
// Summary: Major redesign of CpuTimeLimit (many consequences)
//
// Revision 1.7  2017/09/06 14:08:50  abbott
// Summary: Changed name to TimeoutException
//
// Revision 1.6  2017/07/23 15:32:32  abbott
// Summary: Fixed STUPID bug in myDeactivate
//
// Revision 1.5  2017/07/22 13:03:02  abbott
// Summary: Added new exception InterruptdByTimeout; changed rtn type of myOutputSelf
//
// Revision 1.4  2017/07/21 15:06:10  abbott
// Summary: Major revision -- no longer needs BOOST
//
// Revision 1.3  2017/07/21 13:21:22  abbott
// Summary: Split olf interrupt into two ==> new file SignalWatcher; refactored interrupt and CpuTimeLimit
//
// Revision 1.2  2017/07/15 15:44:44  abbott
// Summary: Corrected error ID name (to ArgTooBig)
//
// Revision 1.1  2017/07/15 15:17:48  abbott
// Summary: Added CpuTimeLimit
//
//
