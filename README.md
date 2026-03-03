Compiler2022

This repository contains the programming assignments for the Compiler Construction (2022) course at National Cheng Kung University.

The project builds a simplified compiler for the μGo language, implemented using Flex (Lex) and Bison (Yacc).

The compiler is developed in three stages:

HW1 – Lexical Analysis

HW2 – Syntax & Semantic Analysis

HW3 – Code Generation

The final compiler translates μGo programs into Java Assembly (Jasmin) and runs them on the JVM.

Project Structure
Compiler2022
│
├── Compiler_HW1   # Lexical Analyzer (scanner)
├── Compiler_HW2   # Parser + Symbol Table
├── Compiler_HW3   # Code Generation (Jasmin)
HW1 – Lexical Analyzer

Implemented a scanner for the μGo language using Flex.

Features:

Recognize tokens such as

keywords (if, for, var, func)

operators (+ - * / %)

identifiers

literals (int, float, string)

Ignore comments and whitespace

Output token stream for the parser

Example:

var a int32 = 3

Output tokens:

VAR IDENT INT ASSIGN INT_LIT
HW2 – Parser and Semantic Analysis

Implemented a LALR(1) parser using Yacc/Bison.

Features:

Grammar parsing for μGo

Arithmetic operations

if, for, switch

Function definitions

Symbol table management

Semantic checking includes:

variable redeclaration

undefined variables

type mismatch

scope handling

HW3 – Code Generation

Extended the parser to generate Jasmin assembly code.

Workflow:

μGo program
   ↓
Flex scanner (.l)
   ↓
Bison parser (.y)
   ↓
Jasmin assembly (.j)
   ↓
JVM bytecode (.class)

The generated .j file is assembled by Jasmin and executed on the Java Virtual Machine.

Requirements

Linux (recommended Ubuntu)

Install dependencies:

sudo apt install flex bison
sudo apt install default-jre
pip3 install local-judge
