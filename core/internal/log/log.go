package log

import "log"

func Debug(msg any, keyvals ...any) { log.Println(append([]any{msg}, keyvals...)...) }
func Warn(msg any, keyvals ...any)  { log.Println(append([]any{msg}, keyvals...)...) }
func Error(msg any, keyvals ...any) { log.Println(append([]any{msg}, keyvals...)...) }
