;;
;; Generates uvect.c from uvect.c.tmpl
;;
;; $Id: uvgen.scm,v 1.1 2004-11-05 10:34:25 shirok Exp $
;;

(use srfi-1)
(use srfi-13)
(use text.tree)
(use util.list)
(use file.util)
(use gauche.sequence)
(use gauche.parseopt)
(use gauche.parameter)

(define p print)

;; overwritten by template files
(define *tmpl-prologue* '())
(define *tmpl-body* '())
(define *tmpl-epilogue* '())
(define *extra-procedure* #f)

;; entry
(define (main args)
  (if (or (null? (cdr args))
          (not (string-suffix? ".tmpl" (cadr args))))
    (usage)
    (let ((ifile (cadr args))
          (rules (make-rules)))
      (process ifile rules)))
  0)

(define (usage)
  (p "Usage: gosh uvgen.scm <file>.tmpl")
  (exit 0))

;; file translation toplevel
(define (process tmpl-file rules)
  (let ((c-file (regexp-replace #/\.tmpl$/ tmpl-file "")))
    (load-template tmpl-file)
    (with-output-to-file c-file
      (lambda ()
        (for-each print *tmpl-prologue*)
        (dolist (rule rules)
          (for-each (cut substitute <> rule) *tmpl-body*))
        (when *extra-procedure*
          (*extra-procedure*))
        (for-each print *tmpl-epilogue*)))))

;; load uvect.tmpl
;; this sets up variables.
(define (load-template tmpl-file)
  (define (translate)
    (let loop ((line (read-line)))
      (cond ((eof-object? line))
            ((string-prefix? "///" line)
             (p (string-drop line 3))
             (loop (read-line)))
            (else
             (p "\"" (regexp-replace-all #/[\\\"]/ line "\\\\\\0") "\"")
             (loop (read-line))))))

  (receive (out name) (sys-mkstemp tmpl-file)
    (with-error-handler
        (lambda (e) (sys-unlink name) (raise e))
      (lambda ()
        (with-output-to-port out
          (cut with-input-from-file tmpl-file
               (cut translate)))
        (close-output-port out)
        (call-with-input-file name load-from-port)
        (sys-unlink name)))))

;; substitute ${param arg ...} in LINE.  output goes to curout.
;; word-alist :: ((<string> . <string-or-proc>) ...)
(define (substitute line words-alist)
  (define (sub key . args)
    (cond ((assoc key words-alist)
           => (lambda (x)
                (if (string? (cdr x))
                  (display (cdr x))
                  (display (apply (cdr x) args)))))
          (else
           (error "unknown substitution word:" key))))
  (with-input-from-string line
    (lambda ()
      (let loop ((ch (read-char)))
        (cond ((eof-object? ch) (newline))
              ((char=? ch #\$)
               (read-char) ;; we count on well-formed template
               (let1 lis (read-list #\})
                 (apply sub lis)
                 (loop (read-char))))
              (else
               (write-char ch)
               (loop (read-char))))))))

;; substitution rules ----------------------------------------------

(define (make-integer-rules)
  (list (make-s8rules)
        (make-u8rules)
        (make-s16rules)
        (make-u16rules)
        (make-s32rules)
        (make-u32rules)
        (make-s64rules)
        (make-u64rules)))

(define (make-flonum-rules)
  (list (make-f32rules)
        (make-f64rules)))

(define (make-rules)
  (append (make-integer-rules) (make-flonum-rules)))

;; common stuff
(define (common-rules tag)
  (let* ((stag  (symbol->string tag))
         (STAG  (string-upcase stag)))
    `((t   . ,stag)
      (T   . ,STAG))))

(define (make-s8rules)
  (list* '(etype . "signed char")
         '(ntype . "long")
         `(UNBOX . ,(lambda (dst src clamp)
                      #`",|dst| = s8unbox(,|src|,, ,|clamp|)"))
         `(BOX   . ,(lambda (dst src)
                      #`",|dst| = SCM_MAKE_INT(,|src|)"))
         `(EQ    . ,(lambda (x y)
                      #`"(,|x| == ,|y|)"))
         `(PRINT . ,(lambda (out elt)
                      #`"Scm_Printf(,|out|,, \"%d\",, ,|elt|)"))
         (common-rules 's8)))

(define (make-u8rules)
  (list* '(etype . "unsigned char")
         '(ntype . "long")
         `(UNBOX . ,(lambda (dst src clamp)
                      #`",|dst| = u8unbox(,|src|,, ,|clamp|)"))
         `(BOX   . ,(lambda (dst src)
                      #`",|dst| = SCM_MAKE_INT(,|src|)"))
         `(EQ    . ,(lambda (x y)
                      #`"(,|x| == ,|y|)"))
         `(PRINT . ,(lambda (out elt)
                      #`"Scm_Printf(,|out|,, \"%d\",, ,|elt|)"))
         (common-rules 'u8)))

(define (make-s16rules)
  (list* '(etype . "short")
         '(ntype . "long")
         `(UNBOX . ,(lambda (dst src clamp)
                      #`",|dst| = s16unbox(,|src|,, ,|clamp|)"))
         `(BOX   . ,(lambda (dst src)
                      #`",|dst| = SCM_MAKE_INT(,|src|)"))
         `(EQ    . ,(lambda (x y)
                      #`"(,|x| == ,|y|)"))
         `(PRINT . ,(lambda (out elt)
                      #`"Scm_Printf(,|out|,, \"%d\",, ,|elt|)"))
         (common-rules 's16)))

(define (make-u16rules)
  (list* '(etype . "unsigned short")
         '(ntype . "long")
         `(UNBOX . ,(lambda (dst src clamp)
                      #`",|dst| = u16unbox(,|src|,, ,|clamp|)"))
         `(BOX   . ,(lambda (dst src)
                      #`",|dst| = SCM_MAKE_INT(,|src|)"))
         `(EQ    . ,(lambda (x y)
                      #`"(,|x| == ,|y|)"))
         `(PRINT . ,(lambda (out elt)
                      #`"Scm_Printf(,|out|,, \"%d\",, ,|elt|)"))
         (common-rules 'u16)))

(define (make-s32rules)
  (list* '(etype . "ScmInt32")
         '(ntype . "long")
         `(UNBOX . ,(lambda (dst src clamp)
                      #`",|dst| = Scm_GetInteger32Clamp(,|src|,, ,|clamp|,, NULL)"))
         `(BOX   . ,(lambda (dst src)
                      #`",|dst| = Scm_MakeInteger(,|src|)"))
         `(EQ    . ,(lambda (x y)
                      #`"(,|x| == ,|y|)"))
         `(PRINT . ,(lambda (out elt)
                      #`"Scm_Printf(,|out|,, \"%d\",, ,|elt|)"))
         (common-rules 's32)))

(define (make-u32rules)
  (list* '(etype . "ScmUInt32")
         '(ntype . "u_long")
         `(UNBOX . ,(lambda (dst src clamp)
                      #`",|dst| = Scm_GetIntegerU32Clamp(,|src|,, ,|clamp|,, NULL)"))
         `(BOX   . ,(lambda (dst src)
                      #`",|dst| = Scm_MakeIntegerU(,|src|)"))
         `(EQ    . ,(lambda (x y)
                      #`"(,|x| == ,|y|)"))
         `(PRINT . ,(lambda (out elt)
                      #`"Scm_Printf(,|out|,, \"%d\",, ,|elt|)"))
         (common-rules 'u32)))

(define (make-s64rules)
  (list* '(etype . "ScmInt64")
         '(ntype . "ScmInt64")
         `(UNBOX . ,(lambda (dst src clamp)
                      #`",|dst| = Scm_GetInteger64Clamp(,|src|,, ,|clamp|,, NULL)"))
         `(BOX   . ,(lambda (dst src)
                      #`",|dst| = Scm_MakeInteger64(,|src|)"))
         `(EQ    . ,(lambda (x y)
                      #`"int64eqv(,|x|,, ,|y|)"))
         `(PRINT . ,(lambda (out elt)
                      #`"int64print(,|out|,, ,|elt|)"))
         (common-rules 's64)))

(define (make-u64rules)
  (list* '(etype . "ScmUInt64")
         '(ntype . "ScmUInt64")
         `(UNBOX . ,(lambda (dst src clamp)
                      #`",|dst| = Scm_GetIntegerU64Clamp(,|src|,, ,|clamp|,, NULL)"))
         `(BOX   . ,(lambda (dst src)
                      #`",|dst| = Scm_MakeIntegerU64(,|src|)"))
         `(EQ    . ,(lambda (x y)
                      #`"uint64eqv(,|x|,, ,|y|)"))
         `(PRINT . ,(lambda (out elt)
                      #`"uint64print(,|out|,, ,|elt|)"))
         (common-rules 'u64)))

(define (make-f32rules)
  (list* '(etype . "float")
         '(ntype . "double")
         `(UNBOX . ,(lambda (dst src clamp)
                      #`",|dst| = (float)Scm_GetDouble(,|src|)"))
         `(BOX   . ,(lambda (dst src)
                      #`",|dst| = Scm_MakeFlonum((double),|src|)"))
         `(EQ    . ,(lambda (x y)
                      #`"(,|x| == ,|y|)"))
         `(PRINT . ,(lambda (out elt)
                      #`"Scm_Printf(,|out|,, \"%f\",, ,|elt|)"))
         (common-rules 'f32)))

(define (make-f64rules)
  (list* '(etype . "double")
         '(ntype . "double")
         `(UNBOX . ,(lambda (dst src clamp)
                      #`",|dst| = Scm_GetDouble(,|src|)"))
         `(BOX   . ,(lambda (dst src)
                      #`",|dst| = Scm_MakeFlonum(,|src|)"))
         `(EQ    . ,(lambda (x y)
                      #`"(,|x| == ,|y|)"))
         `(PRINT . ,(lambda (out elt)
                      #`"Scm_Printf(,|out|,, \"%f\",, ,|elt|)"))
         (common-rules 'f64)))

(define (dummy . _) "/* not implemented */")

;;===============================================================
;; Uvector opertaion generator
;;

(define (generate-numop)
  (for-each
   (lambda (opname Opname Sopname)
     (dolist (rule (make-rules))
       (for-each (cute substitute <> (list* `(opname . ,opname)
                                            `(Opname . ,Opname)
                                            `(Sopname . ,Sopname)
                                            rule))
                 *tmpl-numop*)))
   '("add" "sub" "mul")
   '("Add" "Sub" "Mul")
   '("Add2" "Subtract2" "Multiply2"))
  (dolist (rule (make-flonum-rules))
    (for-each (cute substitute <> (list* '(opname . "div")
                                         '(Opname . "Div")
                                         '(Sopname . "Divide2")
                                         rule))
              *tmpl-numop*)))

(define (generate-bitop)
  (dolist (rule (make-integer-rules))
    (for-each
     (lambda (opname Opname)
       (define (BITOP r v0 v1)
         (let ((tag (assq-ref rule 't))
               (c-op (case (string->symbol opname)
                       ((and) "&") ((ior) "|") ((xor) "^"))))
           (if (member tag '("s8" "u8" "s16" "u16" "s32" "u32"))
             #`",r = ,v0 ,c-op ,v1"
             #`"INT64BITOP(,|r|,, ,|v0|,, ,|c-op|,, ,|v1|)")))
       (define (BITEXT r v)
         (let ((tag (assq-ref rule 't)))
           (if (member tag '("s8" "u8" "s16" "u16" "s32" "u32"))
             #`",|r| = bitext(,|v|)"
             #`",|r| = bitext64(,|v|)")))
       (for-each (cute substitute <> (list* `(opname . ,opname)
                                            `(Opname . ,Opname)
                                            `(BITOP . ,BITOP)
                                            `(BITEXT . ,BITEXT)
                                            rule))
                 *tmpl-bitop*))
     '("and" "ior" "xor")
     '("And" "Ior" "Xor"))))

(define (generate-dotop)
  (dolist (rule (make-rules))
    (let1 tag (string->symbol (assq-ref rule 't))
      (define (ZERO r)
        (case tag
          ((s64 u64)
           #`"SCM_SET_INT64_ZERO(,r)")
          (else
           #`",r = 0")))
      (define (NBOX dst src)
        (case tag
          ((s8 s16 s32) #`",dst = Scm_MakeInteger(,src)")
          ((u8 u16 u32) #`",dst = Scm_MakeIntegerU(,src)")
          ((s64) #`",dst = Scm_MakeInteger64(,src)")
          ((u64) #`",dst = Scm_MakeIntegerU64(,src)")
          ((f32 f64) #`",dst = Scm_MakeFlonum(,src)")))
      (for-each (cute substitute <> (list* `(ZERO . ,ZERO)
                                           `(NBOX . ,NBOX)
                                           rule))
                *tmpl-dotop*))))

(define (generate-rangeop)
  (dolist (rule (make-rules))
    (let ((tag (string->symbol (assq-ref rule 't)))
          (TAG (assq-ref rule 'T)))
      (define (GETLIM r dc v)
        (let1 getter
            (case tag
              ((s8 u8 s16 u16) #`",|tag|unbox(,|v|, SCM_CLAMP_BOTH)")
              ((s32) #`"Scm_GetInteger32Clamp(,|v|, SCM_CLAMP_BOTH, NULL)")
              ((u32) #`"Scm_GetIntegerU32Clamp(,|v|, SCM_CLAMP_BOTH, NULL)")
              ((s64) #`"Scm_GetInteger64Clamp(,|v|, SCM_CLAMP_BOTH, NULL)")
              ((u64) #`"Scm_GetIntegerU64Clamp(,|v|, SCM_CLAMP_BOTH, NULL)")
              ((f32 f64) #`"Scm_GetDouble(,|v|)"))
          (tree->string
           `("if ((",dc" = SCM_FALSEP(",v")) == FALSE) {\n"
             "  ",r" = ",getter";\n"
             "}"))))
      (define (LT a b)
        (case tag
          ((s64 u64) #`"INT64LT(,|a|,, ,|b|)")
          (else      #`"(,|a| < ,|b|)")))
      (dolist (ops `(("range-check" "RangeCheck"
                      ""
                      "return Scm_MakeInteger(i)"
                      "SCM_FALSE")
                     ("clamp" "Clamp"
                      "ScmObj d = Scm_MakeUVector(Scm_ClassOf(SCM_OBJ(x)), SCM_UVECTOR_SIZE(x), SCM_UVECTOR_ELEMENTS(x))"
                      ,#`"SCM_,|TAG|VECTOR_ELEMENTS(d)[i] = val"
                      "d")
                     ("clamp!" "ClampX"
                      ""
                      ,#`"SCM_,|TAG|VECTOR_ELEMENTS(x)[i] = val"
                      "SCM_OBJ(x)")
                     ))
        (for-each (cute substitute <> (list* `(GETLIM . ,GETLIM)
                                             `(LT . ,LT)
                                             `(opname .  ,(ref ops 0))
                                             `(Opname .  ,(ref ops 1))
                                             `(dstdecl . ,(ref ops 2))
                                             `(action .  ,(ref ops 3))
                                             `(okval  .  ,(ref ops 4))
                                             rule))
                  *tmpl-rangeop*)))))