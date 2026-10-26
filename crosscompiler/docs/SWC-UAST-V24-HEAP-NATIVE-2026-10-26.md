# V24 native heap and alias-preserving views (Windows x64)

The production backend now implements `heap_alloc_page`, `heap_load_i64` and
`heap_store_i64` directly in Semantic. Allocation calls the existing Windows
runtime allocator for one writable 4096-byte page. Loads and stores address
`base + index*8`; a store returns the original base pointer, preserving the
runtime's nested store composition. Arguments evaluate once, left to right.
The compiler checks intrinsic kind and arity and rejects unknown intrinsics.

The 37 V24 runtime closures are integrated into the compiler graph. Their
Semantic bodies implement arrays of one to four i64 elements and separately
allocated `[backing, offset, length, capacity]` slice descriptors. Slicing
preserves backing identity; writes through a subview are visible through its
parent. These are native Windows PE executions, not the package's Linux ELF
reference executables.

SWC also consumes the original annotated `IndexExpr` reads/writes and
`SliceExpr` directly. It checks explicit value model/index base, i64 read
results, 64-bit pointer results, alias proof, sentinel bounds policy, receiver
handle proof, exact role arities and write effects/order. Receiver, index and
assigned value retain their original order and are evaluated once. Nested
slices recursively lower into calls to the corresponding runtime closures.
The input graph must contain the required named runtime closures with matching
arity; runtime insertion into an arbitrary input graph is not automatic.

Run `./crosscompiler/verify-uast24.ps1`. It builds each of the 25 archive
runtime cases with 1, 2 and automatic workers; the generated programs compare
full i64 results before returning. Two unchanged source-UAST fixtures verify
nested slicing/read (8) and aliasing write (42) with all three worker settings.
An additional effect-order fixture checks receiver bounds, index and assigned value once in sequence. Eleven rejection fixtures cover missing proof, effects, bounds policy,
representation width, intrinsic kind and arity, preserving existing outputs.
Each successful fixture must produce identical bytes across worker settings.

The compiler source now exceeds 16 MiB. The SMOD per-file reader cap has been
raised to the existing 64-MiB source arena limit, reserving one byte when the
whole arena is available. Existing arena-remaining bounds remain in place.

The raw memory primitives require a valid mapped page and a slot in 0..511.
They provide the same unsafe primitive contract as the archive; a pointer
annotation does not prove arbitrary pointer validity. Allocation-dependent
constructors retain their documented allocation-success precondition. Pages
are not garbage collected or explicitly freed by this runtime. Out-of-bounds
reads return -1; invalid writes and slices return null. General Go panic,
GC/ownership analysis, arbitrary lvalues, strings/maps/interfaces, captures,
exceptions/cleanup and concurrency semantics remain incomplete.

Archive: `UAST-Full-Lowering-Step3-V24.zip`, SHA-256
`549B3F37D0AC4381453DA995604E400BE2ABBD2FA021019EE4FAA13612C9276C`.
Imported Linux-only origin metadata is retained as provenance; the Windows
backend and current verification report provide the new target evidence.
Complete UAST lowerability is not claimed.

Validation: 95 V24 checks plus 226 prior checks pass (321 total). Selfhost generations are byte-identical; 12 workers compile 1,792 functions. Compiler SHA-256: `C2C423D5F0E45501DDB33FC4A0C7CFDCB75CBA2236BEC203CA45CCBE317B47BA`.
