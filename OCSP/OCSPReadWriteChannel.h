//
//  OCSPReadWriteChannel.h
//  OCSP
//
//  Created by William on 21/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPChannel.h"

@interface
OCSPReadWriteChannel<Data> : OCSPChannel<Data>
{
    pthread_mutex_t
    _writing,   // exlusive writer at any given time
    _reading;   // exlusive reader at any given time
    id
    _data;
}
- (BOOL)send:(Data __nullable)value;
- (BOOL)close;
@end
