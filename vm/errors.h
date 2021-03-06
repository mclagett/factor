/* Runtime errors */
typedef enum
{
	ERROR_EXPIRED = 0,
	ERROR_IO,
	ERROR_NOT_IMPLEMENTED,
	ERROR_TYPE,
	ERROR_DIVIDE_BY_ZERO,
	ERROR_SIGNAL,
	ERROR_ARRAY_SIZE,
	ERROR_C_STRING,
	ERROR_FFI,
	ERROR_HEAP_SCAN,
	ERROR_UNDEFINED_SYMBOL,
	ERROR_DS_UNDERFLOW,
	ERROR_DS_OVERFLOW,
	ERROR_RS_UNDERFLOW,
	ERROR_RS_OVERFLOW,
	ERROR_MEMORY,
} F_ERRORTYPE;

void fatal_error(char* msg, CELL tagged);
void critical_error(char* msg, CELL tagged);
DECLARE_PRIMITIVE(die);

void throw_error(CELL error, F_STACK_FRAME *native_stack);
void general_error(F_ERRORTYPE error, CELL arg1, CELL arg2, F_STACK_FRAME *native_stack);
void divide_by_zero_error(F_STACK_FRAME *native_stack);
void memory_protection_error(CELL addr, F_STACK_FRAME *native_stack);
void signal_error(int signal, F_STACK_FRAME *native_stack);
void type_error(CELL type, CELL tagged);
void not_implemented_error(void);

DECLARE_PRIMITIVE(throw);
DECLARE_PRIMITIVE(call_clear);

INLINE void type_check(CELL type, CELL tagged)
{
	if(type_of(tagged) != type) type_error(type,tagged);
}

#define DEFINE_UNTAG(type,check,name) \
	INLINE type *untag_##name(CELL obj) \
	{ \
		type_check(check,obj); \
		return untag_object(obj); \
	}

/* Global variables used to pass fault handler state from signal handler to
user-space */
CELL signal_number;
CELL signal_fault_addr;
void *signal_callstack_top;

void memory_signal_handler_impl(void);
void divide_by_zero_signal_handler_impl(void);
void misc_signal_handler_impl(void);

DECLARE_PRIMITIVE(unimplemented);
