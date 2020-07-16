// RUN: %swift -prespecialize-generic-metadata -target %module-target-future -emit-ir %s | %FileCheck %s -DINT=i%target-ptrsize -DALIGNMENT=%target-alignment

// REQUIRES: VENDOR=apple || OS=linux-gnu
// UNSUPPORTED: CPU=i386 && OS=ios
// UNSUPPORTED: CPU=armv7 && OS=ios
// UNSUPPORTED: CPU=armv7s && OS=ios

// CHECK: @"$sytN" = external{{( dllimport)?}} global %swift.full_type

// CHECK: @"$s4main5ValueVySiGMf" = linkonce_odr hidden constant <{
// CHECK-SAME:    i8**,
// CHECK-SAME:    [[INT]],
// CHECK-SAME:    %swift.type_descriptor*,
// CHECK-SAME:    %swift.type*,
// CHECK-SAME:    i8**,
// CHECK-SAME:    i8**,
// CHECK-SAME:    i32{{(, \[4 x i8\])?}},
// CHECK-SAME:    i64
// CHECK-SAME: }> <{
//                i8** @"$sB[[INT]]_WV",
//                i8** getelementptr inbounds (%swift.vwtable, %swift.vwtable* @"$s4main5ValueVySiGWV", i32 0, i32 0),
// CHECK-SAME:    [[INT]] 512,
// CHECK-SAME:    %swift.type_descriptor* bitcast ({{.+}}$s4main5ValueVMn{{.+}} to %swift.type_descriptor*),
// CHECK-SAME:    %swift.type* @"$sSiN",
// CHECK-SAME:    i8** getelementptr inbounds ([1 x i8*], [1 x i8*]* @"$sSi4main1PAAWP", i32 0, i32 0),
// CHECK-SAME:    i8** getelementptr inbounds ([1 x i8*], [1 x i8*]* @"$sSi4main1QAAWP", i32 0, i32 0),
// CHECK-SAME:    i32 0{{(, \[4 x i8\] zeroinitializer)?}},
// CHECK-SAME:    i64 3
// CHECK-SAME: }>, align [[ALIGNMENT]]

protocol P {}
protocol Q {}
extension Int : P {}
extension Int : Q {}
struct Value<First : P & Q> {
  let first: First
}

@inline(never)
func consume<T>(_ t: T) {
  withExtendedLifetime(t) { t in
  }
}

// CHECK: define hidden swiftcc void @"$s4main4doityyF"() #{{[0-9]+}} {
// CHECK:    call swiftcc void @"$s4main7consumeyyxlF"(%swift.opaque* noalias nocapture %{{[0-9]+}}, %swift.type* getelementptr inbounds (%swift.full_type, %swift.full_type* bitcast (<{ i8**, [[INT]], %swift.type_descriptor*, %swift.type*, i8**, i8**, i32{{(, \[4 x i8\])?}}, i64 }>* @"$s4main5ValueVySiGMf" to %swift.full_type*), i32 0, i32 1))
// CHECK: }
func doit() {
  consume( Value(first: 13) )
}
doit()

// CHECK: ; Function Attrs: noinline nounwind readnone
// CHECK: define hidden swiftcc %swift.metadata_response @"$s4main5ValueVMa"([[INT]] %0, %swift.type* %1, i8** %2, i8** %3) #{{[0-9]+}} {
// CHECK: entry:
// CHECK:   [[ERASED_TYPE:%[0-9]+]] = bitcast %swift.type* %1 to i8*
// CHECK:   [[ERASED_TABLE_1:%[0-9]+]] = bitcast i8** %2 to i8*
// CHECK:   [[ERASED_TABLE_2:%[0-9]+]] = bitcast i8** %3 to i8*
// CHECK:   br label %[[TYPE_COMPARISON_LABEL:[0-9]+]]
// CHECK: [[TYPE_COMPARISON_LABEL]]:
// CHECK:   [[EQUAL_TYPE:%[0-9]+]] = icmp eq i8* bitcast (%swift.type* @"$sSiN" to i8*), [[ERASED_TYPE]]
// CHECK:   [[EQUAL_TYPES:%[0-9]+]] = and i1 true, [[EQUAL_TYPE]]
// CHECK:   [[UNERASED_TABLE_1:%[0-9]+]] = bitcast i8* [[ERASED_TABLE_1]] to i8**
// CHECK:   [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR_1:%[0-9]+]] = load i8*, i8** [[UNERASED_TABLE_1]], align 1
// CHECK:   [[PROVIDED_PROTOCOL_DESCRIPTOR_1:%[0-9]+]] = bitcast i8* [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR_1]] to %swift.protocol_conformance_descriptor*
// CHECK-arm64e:  [[ERASED_TABLE_INT_1:%[0-9]+]] = ptrtoint i8* [[ERASED_TABLE_1]] to i64
// CHECK-arm64e:  [[TABLE_SIGNATURE_1:%[0-9]+]] = call i64 @llvm.ptrauth.blend.i64(i64 [[ERASED_TABLE_INT_1]], i64 50923)
// CHECK-arm64e:  [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_1:%[0-9]+]] = call i64 @llvm.ptrauth.auth.i64(i64 %13, i32 2, i64 [[TABLE_SIGNATURE_1]])
// CHECK-arm64e:  [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_PTR_1:%[0-9]+]] = inttoptr i64 [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_1]] to %swift.protocol_conformance_descriptor*
// CHECK-arm64e:  [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_PTR_INT_1:%[0-9]+]] = ptrtoint %swift.protocol_conformance_descriptor* [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_PTR_1]] to i64
// CHECK-arm64e:  [[PROVIDED_PROTOCOL_DESCRIPTOR_SIGNED_INT_1:%[0-9]+]] = call i64 @llvm.ptrauth.sign.i64(i64 [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_PTR_INT_1]], i32 2, i64 50923)
// CHECK-arm64e:  [[PROVIDED_PROTOCOL_DESCRIPTOR_SIGNED_1:%[0-9]+]] = inttoptr i64 [[PROVIDED_PROTOCOL_DESCRIPTOR_SIGNED_INT_1]] to %swift.protocol_conformance_descriptor*
// CHECK:   [[EQUAL_DESCRIPTORS_1:%[0-9]+]] = call swiftcc i1 @swift_compareProtocolConformanceDescriptors(
// CHECK-SAME:     %swift.protocol_conformance_descriptor* 
// CHECK-arm64e-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR_SIGNED_1]], 
// CHECK-i386-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-x86_64-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-armv7-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-armv7s-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-armv7k-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-arm64-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-SAME:     %swift.protocol_conformance_descriptor* 
// CHECK-SAME:     $sSi4main1PAAMc
// CHECK-SAME:   )
// CHECK:   [[EQUAL_ARGUMENTS_1:%[0-9]+]] = and i1 [[EQUAL_TYPES]], [[EQUAL_DESCRIPTORS_1]]
// CHECK:   [[UNERASED_TABLE_2:%[0-9]+]] = bitcast i8* [[ERASED_TABLE_2]] to i8**
// CHECK:   [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR_2:%[0-9]+]] = load i8*, i8** [[UNERASED_TABLE_2]], align 1
// CHECK:   [[PROVIDED_PROTOCOL_DESCRIPTOR_2:%[0-9]+]] = bitcast i8* [[UNCAST_PROVIDED_PROTOCOL_DESCRIPTOR_2]] to %swift.protocol_conformance_descriptor*
// CHECK-arm64e:  [[ERASED_TABLE_INT_2:%[0-9]+]] = ptrtoint i8* [[ERASED_TABLE_2]] to i64
// CHECK-arm64e:  [[TABLE_SIGNATURE_2:%[0-9]+]] = call i64 @llvm.ptrauth.blend.i64(i64 [[ERASED_TABLE_INT_2]], i64 50923)
// CHECK-arm64e:  [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_2:%[0-9]+]] = call i64 @llvm.ptrauth.auth.i64(i64 %13, i32 2, i64 [[TABLE_SIGNATURE_2]])
// CHECK-arm64e:  [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_PTR_2:%[0-9]+]] = inttoptr i64 [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_2]] to %swift.protocol_conformance_descriptor*
// CHECK-arm64e:  [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_PTR_INT_2:%[0-9]+]] = ptrtoint %swift.protocol_conformance_descriptor* [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_PTR_2]] to i64
// CHECK-arm64e:  [[PROVIDED_PROTOCOL_DESCRIPTOR_SIGNED_INT_2:%[0-9]+]] = call i64 @llvm.ptrauth.sign.i64(i64 [[PROVIDED_PROTOCOL_DESCRIPTOR_AUTHED_PTR_INT_2]], i32 2, i64 50923)
// CHECK-arm64e:  [[PROVIDED_PROTOCOL_DESCRIPTOR_SIGNED_2:%[0-9]+]] = inttoptr i64 [[PROVIDED_PROTOCOL_DESCRIPTOR_SIGNED_INT_2]] to %swift.protocol_conformance_descriptor*
// CHECK:   [[EQUAL_DESCRIPTORS_2:%[0-9]+]] = call swiftcc i1 @swift_compareProtocolConformanceDescriptors(
// CHECK-SAME:     %swift.protocol_conformance_descriptor* 
// CHECK-arm64e-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR_SIGNED_2]], 
// CHECK-i386-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-x86_64-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-armv7-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-armv7s-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-armv7k-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-arm64-SAME:     [[PROVIDED_PROTOCOL_DESCRIPTOR]], 
// CHECK-SAME:     %swift.protocol_conformance_descriptor* 
// CHECK-SAME:     $sSi4main1QAAMc
// CHECK-SAME:   )
// CHECK:   [[EQUAL_ARGUMENTS_2:%[0-9]+]] = and i1 [[EQUAL_ARGUMENTS_1]], [[EQUAL_DESCRIPTORS_2]]
// CHECK:   br i1 [[EQUAL_ARGUMENTS_2]], label %[[EXIT_PRESPECIALIZED:[0-9]+]], label %[[EXIT_NORMAL:[0-9]+]]
// CHECK: [[EXIT_PRESPECIALIZED]]:
// CHECK:   ret %swift.metadata_response { %swift.type* getelementptr inbounds (%swift.full_type, %swift.full_type* bitcast (<{ i8**, [[INT]], %swift.type_descriptor*, %swift.type*, i8**, i8**, i32{{(, \[4 x i8\])?}}, i64 }>* @"$s4main5ValueVySiGMf" to %swift.full_type*), i32 0, i32 1), [[INT]] 0 }
// CHECK: [[EXIT_NORMAL]]:
// CHECK:   {{%[0-9]+}} = call swiftcc %swift.metadata_response @__swift_instantiateGenericMetadata([[INT]] %0, i8* [[ERASED_TYPE]], i8* [[ERASED_TABLE_1]], i8* [[ERASED_TABLE_2]], %swift.type_descriptor* bitcast ({{.+}}$s4main5ValueVMn{{.+}} to %swift.type_descriptor*)) #{{[0-9]+}}
// CHECK:   ret %swift.metadata_response {{%[0-9]+}}
// CHECK: }
