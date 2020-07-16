//===--- TBD.cpp -- generates and validates TBD files ---------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#include "TBD.h"
#include "swift/AST/ASTContext.h"
#include "swift/AST/Decl.h"
#include "swift/AST/DiagnosticEngine.h"
#include "swift/AST/DiagnosticsFrontend.h"
#include "swift/AST/FileUnit.h"
#include "swift/AST/Module.h"
#include "swift/Basic/LLVM.h"
#include "swift/Demangling/Demangle.h"
#include "swift/Frontend/FrontendOptions.h"
#include "swift/TBDGen/TBDGen.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Mangler.h"
#include "llvm/IR/ValueSymbolTable.h"
#include "llvm/Support/FileSystem.h"
#include <vector>

using namespace swift;

static std::vector<StringRef> sortSymbols(llvm::StringSet<> &symbols) {
  std::vector<StringRef> sorted;
  for (auto &symbol : symbols)
    sorted.push_back(symbol.getKey());
  std::sort(sorted.begin(), sorted.end());
  return sorted;
}

bool swift::writeTBD(ModuleDecl *M, StringRef OutputFilename,
                     const TBDGenOptions &Opts) {
  std::error_code EC;
  llvm::raw_fd_ostream OS(OutputFilename, EC, llvm::sys::fs::F_None);
  if (EC) {
    M->getASTContext().Diags.diagnose(SourceLoc(), diag::error_opening_output,
                                      OutputFilename, EC.message());
    return true;
  }

  writeTBDFile(M, OS, Opts);

  return false;
}

bool swift::inputFileKindCanHaveTBDValidated(InputFileKind kind) {
  // Only things that involve an AST can have a TBD file computed, at the
  // moment.
  switch (kind) {
  case InputFileKind::Swift:
  case InputFileKind::SwiftLibrary:
    return true;
  case InputFileKind::SwiftModuleInterface:
    // FIXME: This would be a good test of the interface format.
    return false;
  case InputFileKind::None:
  case InputFileKind::SIL:
  case InputFileKind::LLVM:
    return false;
  }
  llvm_unreachable("unhandled kind");
}

static bool validateSymbols(DiagnosticEngine &diags,
                            const std::vector<std::string> &symbols,
                            const llvm::Module &IRModule,
                            bool diagnoseExtraSymbolsInTBD) {
  llvm::StringSet<> symbolSet;
  symbolSet.insert(symbols.begin(), symbols.end());

  auto error = false;

  // Diff the two sets of symbols, flagging anything outside their intersection.

  // Delay the emission of errors for things in the IR but not TBD, so we can
  // sort them to get a stable order.
  std::vector<StringRef> irNotTBD;

  for (auto &nameValue : IRModule.getValueSymbolTable()) {
    // TBDGen inserts mangled names (usually with a leading '_') into its
    // symbol table, so make sure to mangle IRGen names before comparing them
    // with what TBDGen created.
    auto unmangledName = nameValue.getKey();
    SmallString<128> name;
    llvm::Mangler::getNameWithPrefix(name, unmangledName,
                                     IRModule.getDataLayout());

    auto value = nameValue.getValue();
    if (auto GV = dyn_cast<llvm::GlobalValue>(value)) {
      // Is this a symbol that should be listed?
      auto externallyVisible =
          GV->hasExternalLinkage() && !GV->hasHiddenVisibility();
      if (!GV->isDeclaration() && externallyVisible) {
        // Is it listed?
        if (!symbolSet.erase(name))
          // Note: Add the unmangled name to the irNotTBD list, which is owned
          //       by the IRModule, instead of the mangled name.
          irNotTBD.push_back(unmangledName);
      }
    } else {
      assert(symbolSet.find(name) == symbolSet.end() &&
             "non-global value in value symbol table");
    }
  }

  std::sort(irNotTBD.begin(), irNotTBD.end());
  for (auto &name : irNotTBD) {
    diags.diagnose(SourceLoc(), diag::symbol_in_ir_not_in_tbd, name,
                   Demangle::demangleSymbolAsString(name));
    error = true;
  }

  if (diagnoseExtraSymbolsInTBD) {
    // Look for any extra symbols.
    for (auto &name : sortSymbols(symbolSet)) {
      diags.diagnose(SourceLoc(), diag::symbol_in_tbd_not_in_ir, name,
                     Demangle::demangleSymbolAsString(name));
      error = true;
    }
  }

  if (error) {
    diags.diagnose(SourceLoc(), diag::tbd_validation_failure);
  }

  return error;
}

bool swift::validateTBD(ModuleDecl *M,
                        const llvm::Module &IRModule,
                        const TBDGenOptions &opts,
                        bool diagnoseExtraSymbolsInTBD) {
  auto symbols = getPublicSymbols(TBDGenDescriptor::forModule(M, opts));
  return validateSymbols(M->getASTContext().Diags, symbols, IRModule,
                         diagnoseExtraSymbolsInTBD);
}

bool swift::validateTBD(FileUnit *file,
                        const llvm::Module &IRModule,
                        const TBDGenOptions &opts,
                        bool diagnoseExtraSymbolsInTBD) {
  auto symbols = getPublicSymbols(TBDGenDescriptor::forFile(file, opts));
  return validateSymbols(file->getParentModule()->getASTContext().Diags,
                         symbols, IRModule, diagnoseExtraSymbolsInTBD);
}
