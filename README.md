OCSP
===

My original intention was to implement channels base on thread, saying sending to or receiving from a channel may stuck the current thread, but it turned out to be too consuming for the OS. Thus, I turned to asynchronism and implemented it base on `dispatch_queue_t`.

Usages
---

The execution path of a sequential task should be continued in the callback, as it would be continued synchronously if we had `goroutine` in `ObjC`.

```objective-c
__auto_type const
chan = [[ARWChan<NSNumber *> alloc] init];

[chan send:@42
      with:
 ^(BOOL ok) {
     NSLog(@"The answer has been received!");
 }];

[chan receive:
 ^(NSNumber * _Nullable data, BOOL ok) {
     NSLog(@"Got the ultimate answer %@", data);
}];
```

And, of course, `select` can't be absent.

```objective-c
__auto_type const
receiving = [[ARWChan<NSNumber *> alloc] init];
__auto_type const
sending = [[ARWChan<NSNumber *> alloc] init];

ASelect(^(ASelecting *case_) {
    [receiving receiveIn:case_
                    with:
     ^(NSNumber * _Nullable data, BOOL ok) {
         NSLog(@"Continue with the received value.");
     }];
    [sending send:@42
               in:case_
             with:
     ^(BOOL ok) {
         NSLog(@"Continue with the sent value.");
     }];
    [case_ default:^{
        NSLog(@"Continue anyway.");
    }];
});
```

And, I found it is more convenient to use it with the help of `promise`, given the lack of `goroutine` is something that we can't overcome in `ObjC`.

```objective-c
[RXPromise promiseWithResult:nil]
.then(^id(id _) {
    return
    ORXSelect(^(ORXSelecting *_) { _
        .receive(boss)
        .receive(guys)
        .default_()
        ;
    });
}, nil)
.then(^id(ORXSelected *_) {
    switch (_.index) {
        case 0:
            return colleague.orx_send(@"email");
        case 1:
            return bar.orx_send(@"myself");
        default:
            return cafe.orx_send(@"coding");
    }
}, nil)
;
```

