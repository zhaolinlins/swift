//===--- IRGenRequests.h - IRGen Requests -----------------------*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
//  This file defines IRGen requests.
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_IRGen_REQUESTS_H
#define SWIFT_IRGen_REQUESTS_H

#include "swift/AST/ASTTypeIDs.h"
#include "swift/AST/EvaluatorDependencies.h"
#include "swift/AST/SimpleRequest.h"
#include "swift/Basic/PrimarySpecificPaths.h"
#include "llvm/ADT/StringSet.h"

namespace swift {
class SourceFile;
class IRGenOptions;
class SILModule;
struct TBDGenOptions;

namespace irgen {
  class IRGenModule;
};

}; // namespace swift

namespace llvm {
class GlobalVariable;
class LLVMContext;
class Module;

namespace orc {
class ThreadSafeModule;
}; // namespace orc

}; // namespace llvm

namespace swift {

/// A pair consisting of an \c LLVMContext and an \c llvm::Module that enforces
/// exclusive ownership of those resources, and ensures that they are
/// deallocated or transferred together.
///
/// Note that the underlying module and context are either both valid pointers
/// or both null. This class forbids the remaining cases by construction.
class GeneratedModule final {
private:
  std::unique_ptr<llvm::LLVMContext> Context;
  std::unique_ptr<llvm::Module> Module;

  GeneratedModule() : Context(nullptr), Module(nullptr) {}

  GeneratedModule(GeneratedModule const &) = delete;
  GeneratedModule &operator=(GeneratedModule const &) = delete;

public:
  /// Construct a \c GeneratedModule that owns a given module and context.
  ///
  /// The given pointers must not be null. If a null \c GeneratedModule is
  /// needed, use \c GeneratedModule::null() instead.
  explicit GeneratedModule(std::unique_ptr<llvm::LLVMContext> &&Context,
                           std::unique_ptr<llvm::Module> &&Module)
    : Context(std::move(Context)), Module(std::move(Module)) {
      assert(getModule() && "Use GeneratedModule::null() instead");
      assert(getContext() && "Use GeneratedModule::null() instead");
    }

  GeneratedModule(GeneratedModule &&) = default;
  GeneratedModule& operator=(GeneratedModule &&) = default;

public:
  /// Construct a \c GeneratedModule that does not own any resources.
  static GeneratedModule null() {
    return GeneratedModule{};
  }

public:
  explicit operator bool() const {
    return Module != nullptr && Context != nullptr;
  }

public:
  const llvm::Module *getModule() const { return Module.get(); }
  llvm::Module *getModule() { return Module.get(); }

  const llvm::LLVMContext *getContext() const { return Context.get(); }
  llvm::LLVMContext *getContext() { return Context.get(); }

public:
  /// Release ownership of the context and module to the caller, consuming
  /// this value in the process.
  ///
  /// The REPL is the only caller that needs this. New uses of this function
  /// should be avoided at all costs.
  std::pair<llvm::LLVMContext *, llvm::Module *> release() && {
    return { Context.release(), Module.release() };
  }

public:
  /// Transfers ownership of the underlying module and context to an
  /// ORC-compatible context.
  llvm::orc::ThreadSafeModule intoThreadSafeContext() &&;
};

struct IRGenDescriptor {
  llvm::PointerUnion<ModuleDecl *, SourceFile *> Ctx;

  const IRGenOptions &Opts;
  const TBDGenOptions &TBDOpts;

  SILModule *SILMod;
  StringRef ModuleName;
  const PrimarySpecificPaths &PSPs;
  StringRef PrivateDiscriminator;
  ArrayRef<std::string> parallelOutputFilenames;
  llvm::GlobalVariable **outModuleHash;

  friend llvm::hash_code hash_value(const IRGenDescriptor &owner) {
    return llvm::hash_combine(owner.Ctx);
  }

  friend bool operator==(const IRGenDescriptor &lhs,
                         const IRGenDescriptor &rhs) {
    return lhs.Ctx == rhs.Ctx;
  }

  friend bool operator!=(const IRGenDescriptor &lhs,
                         const IRGenDescriptor &rhs) {
    return !(lhs == rhs);
  }

public:
  static IRGenDescriptor
  forFile(SourceFile &SF, const IRGenOptions &Opts,
          const TBDGenOptions &TBDOpts, std::unique_ptr<SILModule> &&SILMod,
          StringRef ModuleName, const PrimarySpecificPaths &PSPs,
          StringRef PrivateDiscriminator,
          llvm::GlobalVariable **outModuleHash) {
    return IRGenDescriptor{&SF,
                           Opts,
                           TBDOpts,
                           SILMod.release(),
                           ModuleName,
                           PSPs,
                           PrivateDiscriminator,
                           {},
                           outModuleHash};
  }

  static IRGenDescriptor
  forWholeModule(ModuleDecl *M, const IRGenOptions &Opts,
                 const TBDGenOptions &TBDOpts,
                 std::unique_ptr<SILModule> &&SILMod, StringRef ModuleName,
                 const PrimarySpecificPaths &PSPs,
                 ArrayRef<std::string> parallelOutputFilenames,
                 llvm::GlobalVariable **outModuleHash) {
    return IRGenDescriptor{M,
                           Opts,
                           TBDOpts,
                           SILMod.release(),
                           ModuleName,
                           PSPs,
                           "",
                           parallelOutputFilenames,
                           outModuleHash};
  }

  /// Retrieves the files to perform IR generation for.
  TinyPtrVector<FileUnit *> getFiles() const;

  /// For a single file, returns its parent module, otherwise returns the module
  /// itself.
  ModuleDecl *getParentModule() const;

  /// Compute the linker directives to emit.
  std::vector<std::string> getLinkerDirectives() const;
};

/// Report that a request of the given kind is being evaluated, so it
/// can be recorded by the stats reporter.
template<typename Request>
void reportEvaluatedRequest(UnifiedStatsReporter &stats,
                            const Request &request);

class IRGenRequest
    : public SimpleRequest<IRGenRequest, GeneratedModule(IRGenDescriptor),
                           RequestFlags::Uncached |
                               RequestFlags::DependencySource> {
public:
  using SimpleRequest::SimpleRequest;

private:
  friend SimpleRequest;

  // Evaluation.
  GeneratedModule
  evaluate(Evaluator &evaluator, IRGenDescriptor desc) const;

public:
  // Incremental dependencies.
  evaluator::DependencySource
  readDependencySource(const evaluator::DependencyRecorder &) const;
};

void simple_display(llvm::raw_ostream &out, const IRGenDescriptor &d);

SourceLoc extractNearestSourceLoc(const IRGenDescriptor &desc);

/// The zone number for IRGen.
#define SWIFT_TYPEID_ZONE IRGen
#define SWIFT_TYPEID_HEADER "swift/AST/IRGenTypeIDZone.def"
#include "swift/Basic/DefineTypeIDZone.h"
#undef SWIFT_TYPEID_ZONE
#undef SWIFT_TYPEID_HEADER

 // Set up reporting of evaluated requests.
#define SWIFT_REQUEST(Zone, RequestType, Sig, Caching, LocOptions)             \
template<>                                                                     \
inline void reportEvaluatedRequest(UnifiedStatsReporter &stats,                \
                            const RequestType &request) {                      \
  ++stats.getFrontendCounters().RequestType;                                   \
}
#include "swift/AST/IRGenTypeIDZone.def"
#undef SWIFT_REQUEST

} // end namespace swift

#endif // SWIFT_IRGen_REQUESTS_H
