// const std = @import("std");
// const debug = std.log.debug;
// const info = std.log.info;
// const warn = std.log.warn;
// const err = std.log.err;
// const alloc = std.heap.page_allocator;
// const mongo = @cImport({
//     @cInclude("mongoc/mongoc.h");
// });

// pub fn main() !u8 {
//     debug("mongo start!", .{});

//     const uri_str = "mongodb+srv://localhost:27017";
//     mongo.mongoc_init();
//     defer mongo.mongoc_cleanup();

//     var merr: mongo.bson_error_t = undefined;
//     var uri = mongo.mongoc_uri_new_with_error(uri_str, &merr);
//     defer mongo.mongoc_uri_destroy(uri);

//     var client = mongo.mongoc_client_new_from_uri(uri);
//     defer mongo.mongoc_client_destroy(client);

//     _ = mongo.mongoc_client_set_appname(client, "mongo-example");
//     var database = mongo.mongoc_client_get_database(client, "db_name");
//     defer mongo.mongoc_database_destroy(database);

//     var collection = mongo.mongoc_client_get_collection(client, "db_name", "coll_name");
//     defer mongo.mongoc_database_destroy(collection);

//     var command = mongo.BCON_NEW("hello", mongo.BCON_UTF8("world"));
//     defer mongo.bcon_destroy(command);

//     var reply: mongo.bson_t = undefined;
//     var retval = mongo.mongoc_client_command_simple(client, "admin", command, null, &reply, &merr);
//     defer mongo.bson_destroy(reply);
//     if (retval != mongo.MONGOC_RESULT_OK) {
//         err("{s}", merr);
//         return mongo.EXIT_FAILURE;
//     }

//     var str = mongo.bson_as_json(&reply, null);
//     defer mongo.bson_free(str);

//     var insert = mongo.BCON_NEW("hello", mongo.BCON_UTF8("world"));
//     defer mongo.bcon_destroy(insert);

//     if (!mongo.mongoc_collection_insert_one(collection, insert, null, null, &merr)) {
//         debug("{s}", merr.message);
//     }
//     return 0;
// }

// fn BCON_NEW(str: []const u8) []const u8 {
//     return mongo.bcon_new(null, str, null);
// }

// fn BCON_UTF8(str: []const u8) []const u8 {
//     return mongo.bcon_new(null, str, null);
// }
