#include "catui.h"

const char *catui_ext_protocol_cstr(const catui_connect_request *req) {
	return req->protocol;
}
