// RUN: %swift -prespecialize-generic-metadata -target %module-target-future -emit-ir %s | %FileCheck %s -DINT=i%target-ptrsize -DALIGNMENT=%target-alignment

// REQUIRES: VENDOR=apple || OS=linux-gnu
// UNSUPPORTED: CPU=i386 && OS=ios
// UNSUPPORTED: CPU=armv7 && OS=ios
// UNSUPPORTED: CPU=armv7s && OS=ios

// CHECK: @"$sytN" = external{{( dllimport)?}} global %swift.full_type

// CHECK: @"$s4main5ValueOySiGMf" = linkonce_odr hidden constant <{
// CHECK-SAME:    i8**,
// CHECK-SAME:    [[INT]],
// CHECK-SAME:    %swift.type_descriptor*,
// CHECK-SAME:    %swift.type*,
// CHECK-SAME:    i8**,
// CHECK-SAME:    i64
// CHECK-SAME: }> <{
// CHECK-SAME:    i8** getelementptr inbounds (%swift.enum_vwtable, %swift.enum_vwtable* @"$s4main5ValueOySiGWV", i32 0, i32 0),
// CHECK-SAME:    [[INT]] 513,
// CHECK-SAME:    %swift.type_descriptor* bitcast (
// CHECK-SAME:      {{.*}}$s4main5ValueOMn{{.*}} to %swift.type_descriptor*
// CHECK-SAME:    ),
// CHECK-SAME:    %swift.type* @"$sSiN",
// CHECK-SAME:    i8** getelementptr inbounds ([1 x i8*], [1 x i8*]* @"$sSi4main1PAAWP", i32 0, i32 0),
// CHECK-SAME:    i64 3
// CHECK-SAME: }>, align [[ALIGNMENT]]

protocol P {}
extension Int : P {}
enum Value<First : P> {
  case first(First)
}

@inline(never)
func consume<T>(_ t: T) {
  withExtendedLifetime(t) { t in
  }
}

// CHECK: define hidden swiftcc void @"$s4main4doityyF"() #{{[0-9]+}} {
// CHECK:   call swiftcc void @"$s4main7consumeyyxlF"(
// CHECK-SAME:     %swift.opaque* noalias nocapture %{{[0-9]+}}, 
// CHECK-SAME:     %swift.type* getelementptr inbounds (
// CHECK-SAME:       %swift.full_type, 
// CHECK-SAME:       %swift.full_type* bitcast (
// CHECK-SAME:         <{ 
// CHECK-SAME:           i8**, 
// CHECK-SAME:           [[INT]], 
// CHECK-SAME:           %swift.type_descriptor*, 
// CHECK-SAME:           %swift.type*, 
// CHECK-SAME:           i8**, 
// CHECK-SAME:           i64 
// CHECK-SAME:         }>* @"$s4main5ValueOySiGMf" 
// CHECK-SAME:         to %swift.full_type*
// CHECK-SAME:       ), 
// CHECK-SAME:       i32 0, 
// CHECK-SAME:       i32 1
// CHECK-SAME:     )
// CHECK-SAME:   )
// CHECK: }
func doit() {
  consume( Value.first(13) )
}
doit()

// CHECK: ; Function Attrs: noinline nounwind readnone
// CHECK: define hidden swiftcc %swift.metadata_response @"$s4main5ValueOMa"([[INT]] %0, %swift.type* %1, i8** %2) #{{[0-9]+}} {
// CHECK: entry:
// CHECK:   [[ERASED_TYPE:%[0-9]+]] = bitcast %swift.type* %1 to i8*
// CHECK:   [[ERASED_TABLE:%[0-9]+]] = bitcast i8** %2 to i8*
// CHECK:   br label %[[TYPE_COMPARISON_LABEL:[0-9]+]]
// CHECK: [[TYPE_COMPARISON_LABEL]]:
// CHECK:   [[EQUAL_TYPE:%[0-9]+]] = icmp eq i8* bitcast (%swift.type* @"$sSiN" to i8*), [[ERASED_TYPE]]
// CHECK:   [[EQUAL_TYPES:%[0-9]+]] = and i1 true, [[EQUAL_TYPE]]
// CHECK:   [[ARGUMENT_BUFFER:%[0-9]+]] = bitcast i8* [[ERASED_TABLE]] to i8**
// CHECK:   [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR:%[0-9]+]] = load i8*, i8** [[ARGUMENT_BUFFER]], align 1
// CHECK:   [[PROVIDED_PROTOCOL_DESCRIPTOR:%[0-9]+]] = bitcast i8* [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR]] to %swift.protocol_conformance_descriptor*
// CHECK-arm64e:  [[ERASED_TABLE_INT:%[0-9]+]] = ptrtoint i8* [[ERASED_TABLE]] to i64
// CHECK-arm64e:  [[TABLE_SIGNATURE:%[0-9]+]] = call i64 @llvm.ptrauth.blend.i64(i64 [[ERASED_TABLE_INT]], i64 50923)
// CHECK-arm64e:  [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED:%[0-9]+]] = call i64 @llvm.ptrauth.auth.i64(i64 %13, i32 2, i64 [[TABLE_SIGNATURE]])
// CHECK-arm64e:  [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_PTR:%[0-9]+]] = inttoptr i64 [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED]] to %swift.protocol_conformance_descriptor*
// CHECK-arm64e:  [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_PTR_INT:%[0-9]+]] = ptrtoint %swift.protocol_conformance_descriptor* [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_PTR]] to i64
// CHECK-arm64e:  [[PROVIDED_PROTOCOL_DESCRIPTOR_SIGNED_INT:%[0-9]+]] = call i64 @llvm.ptrauth.sign.i64(i64 [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_PTR_INT]], i32 2, i64 50923)
// CHECK-arm64e:  [[PROVIDED_PROTOCOL_DESCRIPTOR_SIGNED:%[0-9]+]] = inttoptr i64 [[PROVIDED_PROTOCOL_DESCRIPTOR_SIGNED_INT]] to %swift.protocol_conformance_descriptor*
// CHECK:   [[EQUAL_DESCRIPTORS:%[0-9]+]] = call swiftcc i1 @swift_compareProtocolConformanceDescriptors(
// CHECK-SAME:     %swift.protocol_conformance_descriptor* 
// CHECK-arm64e-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR_SIGNED]], 
// CHECK-i386-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-x86_64-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-armv7-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-armv7s-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-armv7k-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-arm64-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-SAME:     %swift.protocol_conformance_descriptor* 
// CHECK-SAME:     $sSi4main1PAAMc
// CHECK-SAME:   )
// CHECK:   [[EQUAL_ARGUMENTS:%[0-9]+]] = and i1 [[EQUAL_TYPES]], [[EQUAL_DESCRIPTORS]]
// CHECK:   br i1 [[EQUAL_ARGUMENTS]], label %[[EXIT_PRESPECIALIZED:[0-9]+]], label %[[EXIT_NORMAL:[0-9]+]]
// CHECK: [[EXIT_PRESPECIALIZED]]:
// CHECK:   ret %swift.metadata_response { 
// CHECK-SAME:     %swift.type* getelementptr inbounds (
// CHECK-SAME:       %swift.full_type, 
// CHECK-SAME:       %swift.full_type* bitcast (
// CHECK-SAME:         <{ 
// CHECK-SAME:           i8**, 
// CHECK-SAME:           [[INT]], 
// CHECK-SAME:           %swift.type_descriptor*, 
// CHECK-SAME:           %swift.type*, 
// CHECK-SAME:           i8**, 
// CHECK-SAME:           i64 
// CHECK-SAME:         }>* @"$s4main5ValueOySiGMf" 
// CHECK-SAME:         to %swift.full_type*
// CHECK-SAME:       ), 
// CHECK-SAME:       i32 0, 
// CHECK-SAME:       i32 1
// CHECK-SAME:     ), 
// CHECK-SAME:     [[INT]] 0 
// CHECK-SAME:   }
// CHECK: [[EXIT_NORMAL]]:
// CHECK:   {{%[0-9]+}} = call swiftcc %swift.metadata_response @__swift_instantiateGenericMetadata(
// CHECK-SAME:     [[INT]] %0, 
// CHECK-SAME:     i8* [[ERASED_TYPE]], 
// CHECK-SAME:     i8* [[ERASED_TABLE]], 
// CHECK-SAME:     i8* undef, 
// CHECK-SAME:     %swift.type_descriptor* bitcast (
// CHECK-SAME:       {{.*}}$s4main5ValueOMn{{.*}} to %swift.type_descriptor*
// CHECK-SAME:     )
// CHECK-SAME:   )
// CHECK:   ret %swift.metadata_response {{%[0-9]+}}
// CHECK: }
