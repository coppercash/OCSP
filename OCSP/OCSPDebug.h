//
//  OCSPDebug.h
//  OCSP
//
//  Created by William on 10/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#ifdef DEBUG
#   define OCSPDEBUG
#endif

#ifdef OCSPDEBUG
#   define OCSPLog(...) NSLog(__VA_ARGS__)
#else
#   define OCSPLog(...) (void)0
#endif
