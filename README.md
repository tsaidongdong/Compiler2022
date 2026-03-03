# Compiler2022

This repository contains the programming assignments for the **Compiler Construction (2022)** course at **National Cheng Kung University (NCKU)**.

The project builds a simplified compiler for the **μGo language**, implemented using **Flex (Lex)** and **Bison (Yacc)**.

The compiler is developed in three stages:

- **HW1 – Lexical Analysis**
- **HW2 – Syntax & Semantic Analysis**
- **HW3 – Code Generation**

The final compiler translates μGo programs into **Java Assembly (Jasmin)** and runs them on the **Java Virtual Machine (JVM)**.

---

## Project Structure
```bash
Compiler2022
│
├── Compiler_HW1 # Lexical Analyzer (scanner)
├── Compiler_HW2 # Parser + Symbol Table
└── Compiler_HW3 # Code Generation (Jasmin)
```


### 1. HW1 – 詞法分析 (Lexical Analysis)
實作 μGo 語言的 Scanner，主要功能包含：
* 識別關鍵字如 `if`, `for`, `var`, `func`, `package`, `println` 等。
* 識別運算子（`+`, `-`, `*`, `/`, `%`）與各類字面量（`int32`, `float32`, `string`）。
* 處理並忽略 C 語言風格的註釋與空白字元。

### 2. HW2 – 語法與語意分析 (Syntax & Semantic Analysis)
實作 LALR(1) Parser 並建立 **Symbol Table** 以進行語意檢查：
* **作用域管理 (Scoping)**：支援嵌套作用域，正確處理變數在不同 Block 中的存取範圍。
* **符號表操作**：實作 `create`, `insert`, `lookup`, `dump` 等函數來管理變數資訊。
* **錯誤處理**：檢查變數重複宣告 (Redeclared) 以及未定義變數 (Undefined) 等錯誤。

### 3. HW3 – 程式碼產生 (Code Generation)
將語法分析後的結果轉譯為 **Jasmin 組語**：
* 支援算術運算指令（如 `iadd`, `imul`, `ineg`)。
* 支援流程控制轉譯，包含 `if`, `for`, `switch` 等指令跳轉。
* 產生可執行的 `.j` 檔案，並透過 `jasmin.jar` 轉為 Java Bytecode。

---

## Compiler Pipeline

```bash
μGo program (.go)
↓
Lexical Analysis (Flex scanner)
↓
Syntax & Semantic Analysis (Bison parser)
↓
Code Generation (Jasmin assembly)
↓
Jasmin Assembler
↓
JVM bytecode (.class)
↓
Java Virtual Machine (JVM)

The generated `.j` file is assembled by **Jasmin** and executed on the **Java Virtual Machine**.
