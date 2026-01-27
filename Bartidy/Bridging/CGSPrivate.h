#ifndef CGSPrivate_h
#define CGSPrivate_h

#include <CoreGraphics/CoreGraphics.h>

typedef int CGSConnectionID;
typedef uint32_t CGSWindowID;

extern CGSConnectionID CGSMainConnectionID(void);

extern CGError CGSSetWindowAlpha(
    CGSConnectionID cid,
    CGSWindowID wid,
    float alpha
);

extern CGError CGSGetWindowAlpha(
    CGSConnectionID cid,
    CGSWindowID wid,
    float *outAlpha
);

extern CGError CGSMoveWindow(
    CGSConnectionID cid,
    CGSWindowID wid,
    const CGPoint *point
);

extern CGError CGSGetWindowBounds(
    CGSConnectionID cid,
    CGSWindowID wid,
    CGRect *outBounds
);

extern CGError CGSGetWindowOwner(
    CGSConnectionID cid,
    CGSWindowID wid,
    int *outPID
);

extern CGError CGSGetWindowLevel(
    CGSConnectionID cid,
    CGSWindowID wid,
    int *outLevel
);

#endif
