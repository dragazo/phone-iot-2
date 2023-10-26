#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
typedef struct _Dart_Handle* Dart_Handle;

typedef struct DartCObject DartCObject;

typedef int64_t DartPort;

typedef bool (*DartPostCObjectFnType)(DartPort port_id, void *message);

typedef struct wire_uint_8_list {
  uint8_t *ptr;
  int32_t len;
} wire_uint_8_list;

typedef struct wire_RustCommand_SetProject {
  struct wire_uint_8_list *xml;
} wire_RustCommand_SetProject;

typedef struct wire_RustCommand_Start {

} wire_RustCommand_Start;

typedef struct wire_RustCommand_Stop {

} wire_RustCommand_Stop;

typedef struct wire_RustCommand_TogglePaused {

} wire_RustCommand_TogglePaused;

typedef struct wire_DartValue_Bool {
  bool field0;
} wire_DartValue_Bool;

typedef struct wire_DartValue_Number {
  double field0;
} wire_DartValue_Number;

typedef struct wire_DartValue_String {
  struct wire_uint_8_list *field0;
} wire_DartValue_String;

typedef struct wire_list_dart_value {
  struct wire_DartValue *ptr;
  int32_t len;
} wire_list_dart_value;

typedef struct wire_DartValue_List {
  struct wire_list_dart_value *field0;
} wire_DartValue_List;

typedef struct wire_DartValue_Image {
  struct wire_uint_8_list *field0;
} wire_DartValue_Image;

typedef union DartValueKind {
  struct wire_DartValue_Bool *Bool;
  struct wire_DartValue_Number *Number;
  struct wire_DartValue_String *String;
  struct wire_DartValue_List *List;
  struct wire_DartValue_Image *Image;
} DartValueKind;

typedef struct wire_DartValue {
  int32_t tag;
  union DartValueKind *kind;
} wire_DartValue;

typedef struct wire___record__String_dart_value {
  struct wire_uint_8_list *field0;
  struct wire_DartValue field1;
} wire___record__String_dart_value;

typedef struct wire_list___record__String_dart_value {
  struct wire___record__String_dart_value *ptr;
  int32_t len;
} wire_list___record__String_dart_value;

typedef struct wire_RustCommand_InjectMessage {
  struct wire_uint_8_list *msg_type;
  struct wire_list___record__String_dart_value *values;
} wire_RustCommand_InjectMessage;

typedef union RustCommandKind {
  struct wire_RustCommand_SetProject *SetProject;
  struct wire_RustCommand_Start *Start;
  struct wire_RustCommand_Stop *Stop;
  struct wire_RustCommand_TogglePaused *TogglePaused;
  struct wire_RustCommand_InjectMessage *InjectMessage;
} RustCommandKind;

typedef struct wire_RustCommand {
  int32_t tag;
  union RustCommandKind *kind;
} wire_RustCommand;

typedef struct wire_DartRequestKey {
  uintptr_t value;
} wire_DartRequestKey;

typedef struct wire_RequestResult_Ok {
  struct wire_DartValue *field0;
} wire_RequestResult_Ok;

typedef struct wire_RequestResult_Err {
  struct wire_uint_8_list *field0;
} wire_RequestResult_Err;

typedef union RequestResultKind {
  struct wire_RequestResult_Ok *Ok;
  struct wire_RequestResult_Err *Err;
} RequestResultKind;

typedef struct wire_RequestResult {
  int32_t tag;
  union RequestResultKind *kind;
} wire_RequestResult;

typedef struct DartCObject *WireSyncReturn;

void store_dart_post_cobject(DartPostCObjectFnType ptr);

Dart_Handle get_dart_object(uintptr_t ptr);

void drop_dart_object(uintptr_t ptr);

uintptr_t new_dart_opaque(Dart_Handle handle);

intptr_t init_frb_dart_api_dl(void *obj);

void wire_initialize(int64_t port_,
                     struct wire_uint_8_list *device_id,
                     int32_t utc_offset_in_seconds);

void wire_send_command(int64_t port_, struct wire_RustCommand *cmd);

void wire_recv_commands(int64_t port_);

void wire_complete_request(int64_t port_,
                           struct wire_DartRequestKey *key,
                           struct wire_RequestResult *result);

struct wire_DartRequestKey *new_box_autoadd_dart_request_key_0(void);

struct wire_DartValue *new_box_autoadd_dart_value_0(void);

struct wire_RequestResult *new_box_autoadd_request_result_0(void);

struct wire_RustCommand *new_box_autoadd_rust_command_0(void);

struct wire_list___record__String_dart_value *new_list___record__String_dart_value_0(int32_t len);

struct wire_list_dart_value *new_list_dart_value_0(int32_t len);

struct wire_uint_8_list *new_uint_8_list_0(int32_t len);

union DartValueKind *inflate_DartValue_Bool(void);

union DartValueKind *inflate_DartValue_Number(void);

union DartValueKind *inflate_DartValue_String(void);

union DartValueKind *inflate_DartValue_List(void);

union DartValueKind *inflate_DartValue_Image(void);

union RequestResultKind *inflate_RequestResult_Ok(void);

union RequestResultKind *inflate_RequestResult_Err(void);

union RustCommandKind *inflate_RustCommand_SetProject(void);

union RustCommandKind *inflate_RustCommand_InjectMessage(void);

void free_WireSyncReturn(WireSyncReturn ptr);

static int64_t dummy_method_to_enforce_bundling(void) {
    int64_t dummy_var = 0;
    dummy_var ^= ((int64_t) (void*) wire_initialize);
    dummy_var ^= ((int64_t) (void*) wire_send_command);
    dummy_var ^= ((int64_t) (void*) wire_recv_commands);
    dummy_var ^= ((int64_t) (void*) wire_complete_request);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_dart_request_key_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_dart_value_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_request_result_0);
    dummy_var ^= ((int64_t) (void*) new_box_autoadd_rust_command_0);
    dummy_var ^= ((int64_t) (void*) new_list___record__String_dart_value_0);
    dummy_var ^= ((int64_t) (void*) new_list_dart_value_0);
    dummy_var ^= ((int64_t) (void*) new_uint_8_list_0);
    dummy_var ^= ((int64_t) (void*) inflate_DartValue_Bool);
    dummy_var ^= ((int64_t) (void*) inflate_DartValue_Number);
    dummy_var ^= ((int64_t) (void*) inflate_DartValue_String);
    dummy_var ^= ((int64_t) (void*) inflate_DartValue_List);
    dummy_var ^= ((int64_t) (void*) inflate_DartValue_Image);
    dummy_var ^= ((int64_t) (void*) inflate_RequestResult_Ok);
    dummy_var ^= ((int64_t) (void*) inflate_RequestResult_Err);
    dummy_var ^= ((int64_t) (void*) inflate_RustCommand_SetProject);
    dummy_var ^= ((int64_t) (void*) inflate_RustCommand_InjectMessage);
    dummy_var ^= ((int64_t) (void*) free_WireSyncReturn);
    dummy_var ^= ((int64_t) (void*) store_dart_post_cobject);
    dummy_var ^= ((int64_t) (void*) get_dart_object);
    dummy_var ^= ((int64_t) (void*) drop_dart_object);
    dummy_var ^= ((int64_t) (void*) new_dart_opaque);
    return dummy_var;
}
