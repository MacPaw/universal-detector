/*
 * WrappedUniversalDetector.cpp
 *
 * Copyright (c) 2017-present, MacPaw Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */
#include "WrappedUniversalDetector.h"

#include "universalchardet/nscore.h"
#include "universalchardet/nsUniversalDetector.h"
#include "universalchardet/nsCharSetProber.h"


class wrappedUniversalDetector:public nsUniversalDetector
{
	public:
	wrappedUniversalDetector():nsUniversalDetector(NS_FILTER_ALL) {}

	void Report(const char* aCharset) {}

	const char *charset(float &confidence)
	{
		if(!mGotData)
		{
			confidence=0;
			return 0;
		}

		if(mDetectedCharset)
		{
			confidence=1;
			return mDetectedCharset;
		}

		switch(mInputState)
		{
			case eHighbyte:
			{
				float proberConfidence;
				float maxProberConfidence = (float)0.0;
				PRInt32 maxProber = 0;

				for (PRInt32 i = 0; i < NUM_OF_CHARSET_PROBERS; i++)
				{
					proberConfidence = mCharSetProbers[i]->GetConfidence();
					if (proberConfidence > maxProberConfidence)
					{
						maxProberConfidence = proberConfidence;
						maxProber = i;
					}
				}

				confidence=maxProberConfidence;
				return mCharSetProbers[maxProber]->GetCharSetName();
			}
			break;

			case ePureAscii:
				confidence=0;
				return "US-ASCII";

			default:
				break;
		}

		confidence=0;
		return 0;
	}

	bool done()
	{
		if(mDetectedCharset) return true;
		return false;
	}

	void reset() { Reset(); }
};



extern "C" {

void *AllocUniversalDetector()
{
	return (void *)new wrappedUniversalDetector;
}

void FreeUniversalDetector(void *detectorptr)
{
	delete (wrappedUniversalDetector *)detectorptr;
}

void UniversalDetectorHandleData(void *detectorptr,const char *data,int length)
{
	if(length==0) return; // There seems to be a bug in UniversalDetector that accesses beyond the end of 0-length buffers.
	wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorptr;
	if(detector->done()) return;
	detector->HandleData(data,length);
}

void UniversalDetectorReset(void *detectorptr)
{
	wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorptr;
	detector->reset();
}

int UniversalDetectorDone(void *detectorptr)
{
	wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorptr;
	return detector->done()?1:0;
}

const char *UniversalDetectorCharset(void *detectorptr,float *confidence)
{
	wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorptr;
	return detector->charset(*confidence);
}

}
