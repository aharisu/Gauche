/*
 * termios.h - termios interface
 *
 *   Copyright (c) 2000-2004 Shiro Kawai, All rights reserved.
 * 
 *   Redistribution and use in source and binary forms, with or without
 *   modification, are permitted provided that the following conditions
 *   are met:
 * 
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *   3. Neither the name of the authors nor the names of its contributors
 *      may be used to endorse or promote products derived from this
 *      software without specific prior written permission.
 *
 *   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *   TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  $Id: termios.h,v 1.5 2004-09-12 02:00:49 shirok Exp $
 */

#ifndef GAUCHE_TERMIOS_H
#define GAUCHE_TERMIOS_H

#include <gauche.h>
#include "gauche/uvector.h"

#if !defined(__MINGW32__)

#include <termios.h>
#ifdef HAVE_PTY_H
#include <pty.h>
#endif
#ifdef HAVE_UTIL_H
#include <util.h>
#endif
#ifdef HAVE_LIBUTIL_H
#include <libutil.h>
#endif
#include <unistd.h>

/*
 * NB: ScmSysTermiosRec doubly holds c_cc values, ie term.c_cc and cc.
 * All functions other than syscall interfaces should use cc, not
 * term.c_cc.  When it's necessary to use term.c_cc, sync cc and term.c_cc
 * by using termios_copyin_cc() and termios_copyout_cc().
 */
typedef struct ScmSysTermiosRec {
    SCM_HEADER;
    struct termios term;
    ScmObj cc;
} ScmSysTermios;

SCM_CLASS_DECL(Scm_SysTermiosClass);
#define SCM_CLASS_SYS_TERMIOS   (&Scm_SysTermiosClass)
#define SCM_SYS_TERMIOS(obj)    ((ScmSysTermios*)(obj))
#define SCM_SYS_TERMIOS_P(obj)  (SCM_XTYPEP(obj, SCM_CLASS_SYS_TERMIOS))

ScmObj Scm_MakeSysTermios(void);

void termios_copyin_cc(ScmSysTermios* t);
void termios_copyout_cc(ScmSysTermios* t);

#ifdef HAVE_OPENPTY
ScmObj Scm_Openpty(ScmObj slaveterm);
#endif
#ifdef HAVE_FORKPTY
ScmObj Scm_Forkpty(ScmObj slaveterm);
#endif

#endif /* !defined(__MINGW32__) */

#endif /* GAUCHE_TERMIOS_H */
