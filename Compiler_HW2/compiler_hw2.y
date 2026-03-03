/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_hw_common.h" //Extern variables that communicate with lex
    // #define YYDEBUG 1
    // int yydebug = 1;

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    int yylex_destroy ();
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    /* Symbol table function - you can add new functions if needed. */
    static void create_symbol();
    static void insert_symbol(char *name,char *type,char *func_sig,int scope,int yyl);
    static void *lookup_symbol(char *name);
    static void dump_symbol();
    static void check_type(char*a,char*b,int op);
    static int check_redclared(char* name);
    
    /* Global variables */
    typedef struct _node node;
    struct  _node {
        char *name;
        char *type;
        int addr;
        int lineno;
        char *func_sig;
        node *next;
    };

    node *sym_table[10] = { NULL };
    int cur_Scope = -1;
    int curAddr = -1;
%}

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 *  - you can add new fields if needed.
 */
%union {
    int i_val;
    float f_val;
    char *s_val;
    bool b_val;
    /* ... */
}

/* Token without return */
%token VAR NEWLINE
%token INT FLOAT BOOL STRING TRUE FALSE
%token IF ELSE FOR SWITCH CASE PRINT PRINTLN
%token INC DEC GEQ LEQ EQL NEQ
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN QUO_ASSIGN REM_ASSIGN
%token '(' ')' '[' ']' '{' '}' ';' ',' ':'
%token PACKAGE RETURN FUNC DEFAULT
%left '+' '-' '*' '/' '%'
%left GEQ LEQ EQL NEQ '>' '<'
%left LAND LOR

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <s_val> STRING_LIT
%token <f_val> FLOAT_LIT
%token <s_val> IDENT

/* Nonterminal with return, which need to sepcify type */
%type <s_val> cmp_op add_op mul_op unary_op assign_op
%type <s_val> LeftExpressionStmt ExpressionStmt Term1 Term2 Term3 Term4 
%type <s_val> UnaryExpr PrimaryExpr Operand ConversionExpr Literal FuncOpen Type

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : GlobalStatementList { dump_symbol();}
;

GlobalStatementList 
    : GlobalStatementList GlobalStatement
    | {create_symbol();} GlobalStatement
;

GlobalStatement
    : PackageStmt NEWLINE
    | FunctionDeclStmt
    | NEWLINE
;


PackageStmt
    : PACKAGE IDENT{
        printf("package: %s\n", $<s_val>2);
    }
;

FunctionDeclStmt
    : FuncOpen '(' {
        printf("func_signature: (");
    } ParameterList {
        printf(")");
    } ')'   ReturnType {
    	int check=check_redclared($<s_val>2);
        if(check<1){
            insert_symbol($<s_val>1,"func","()V",0,3);
        }
        else{
            printf("error:%d: %s redeclared in this block. previous declaration at line %d\n", yylineno, $<s_val>1, check);
        }
    } FuncBlock {dump_symbol();}
;

FuncOpen
    : FUNC IDENT {
        printf("func: %s\n", $<s_val>2);
        create_symbol();    
        $$=$<s_val>2;
    }
;

ParameterList
    : IDENT Type
    | ParameterList ',' IDENT Type
    |
;

ReturnType
    :Type {
    	if(strcmp($<s_val>1, "int32") == 0){
    		printf("int32\n");
    	}
    	else{
    		printf("float32\n");
    	}
    }                                 
    | {printf("V\n");}
;

FuncBlock
    :'{' StatementList '}' 
;

ReturnStmt 
    : RETURN {printf("return\n"); printf("\n");} ExpressionStmt
;

StatementList
    : StatementList Statement
    | Statement 
;

Statement
    : DeclarationStmt NEWLINE
    | SimpleStmt NEWLINE
    | Block
    | IfStmt
    | ForStmt
    | SwitchStmt
    | CaseStmt
    | PrintStmt NEWLINE
    | ReturnStmt  NEWLINE
    | NEWLINE
;

SimpleStmt
    : AssignmentStmt
    | ExpressionStmt
    | IncDecStmt
;

DeclarationStmt
: VAR IDENT Type {
	int check=check_redclared($<s_val>2);
	if(check<1){
		insert_symbol($<s_val>2, $<s_val>3, "-",cur_Scope,yylineno);
	}
	else{
		printf("error:%d: %s redeclared in this block. previous declaration at line %d\n", yylineno, $<s_val>2, check);
		insert_symbol($<s_val>2, $<s_val>3, "-",cur_Scope,yylineno);
	}
    
}
| VAR IDENT Type '=' ExpressionStmt {
    	int check=check_redclared($<s_val>2);
	if(check<1){
		insert_symbol($<s_val>2, $<s_val>3, "-",cur_Scope,yylineno);
	}
	else{
		printf("error:%d: %s redeclared in this block. previous declaration at line %d\n", yylineno, $<s_val>2, check);
		insert_symbol($<s_val>2, $<s_val>3, "-",cur_Scope,yylineno);
	}
}
;

AssignmentStmt
    : LeftExpressionStmt assign_op ExpressionStmt {
        if(strcmp($<s_val>1,$<s_val>3)!=0){
            if(strcmp($<s_val>1,"undefined")!=0 && strcmp($<s_val>3,"undefined")!=0){
                printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",yylineno,$<s_val>2,$<s_val>1,$<s_val>3);
            }
            if(strcmp($<s_val>1,"undefined")==0 && strcmp($<s_val>3,"undefined")!=0){
                printf("error:%d: invalid operation: %s (mismatched types ERROR and %s)\n",yylineno,$<s_val>2,$<s_val>3);
            }
        }
        printf("%s\n", $<s_val>2);
    }    
;

LeftExpressionStmt
    : ExpressionStmt 
;

assign_op
    : '='               { $$ = "ASSIGN"; }
    | ADD_ASSIGN        { $$ = "ADD"; }
    | SUB_ASSIGN        { $$ = "SUB"; }
    | MUL_ASSIGN        { $$ = "MUL"; }
    | QUO_ASSIGN        { $$ = "QUO"; }
    | REM_ASSIGN        { $$ = "REM"; }
;

IncDecStmt
    : ExpressionStmt INC { printf("INC\n"); }
    | ExpressionStmt DEC { printf("DEC\n"); }     
;

Type
    : INT { $$ =strdup("int32"); }
    | FLOAT { $$ =strdup("float32"); }
    | STRING { $$ =strdup("string"); }
    | BOOL { $$ =strdup("bool"); }
;

ExpressionStmt
    : ExpressionStmt LOR Term1 {
                                    check_type($<s_val>1,$<s_val>3,0);
                                    printf("LOR\n"); 
                                    $$ = "bool";
                                }
    | Term1
;

Term1
    : Term1 LAND Term2 {
                            check_type($<s_val>1,$<s_val>3,1);
                            printf("LAND\n"); 
                            $$ = "bool";
                        }
    | Term2
;

Term2
    : Term2 cmp_op Term3 { 
                            if(strcmp($<s_val>1,"undefined")==0 && strcmp($<s_val>3,"undefined")!=0){
                                printf("error:%d: invalid operation: %s (mismatched types ERROR and %s)\n",yylineno+1,$<s_val>2,$<s_val>3);
                            }
                            printf("%s\n", $<s_val>2); 
                            $$ = "bool";
                        }
    | Term3
;

Term3
    : Term3 add_op Term4 {
                            if (strcmp($<s_val>1, $<s_val>3) == 0)
                                $$ = $<s_val>1;
                            else if(strcmp($<s_val>1,"undefined")!=0 && strcmp($<s_val>3,"undefined")!=0){
                                printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n",yylineno,$<s_val>2,$<s_val>1,$<s_val>3);
                            }
                            printf("%s\n", $<s_val>2);
                        }
    | Term4
;

Term4
    : Term4 mul_op UnaryExpr {	
                                if(strcmp($<s_val>2,"REM")==0){
                                	check_type($<s_val>1,$<s_val>3,4);
                                }
                                printf("%s\n", $<s_val>2);
                                if (strcmp($<s_val>1, $<s_val>3) == 0)
                                    $$ = $<s_val>1;
                            }
    | UnaryExpr
;

UnaryExpr
    : PrimaryExpr
    | unary_op UnaryExpr {
                            printf("%s\n", $<s_val>1);
                            $$ = $<s_val>2;
                        }
;

cmp_op
    : EQL       
    | NEQ       
    | '<'       
    | LEQ       
    | '>'       
    | GEQ       
;

add_op
    : '+'       
    | '-'       
;

mul_op
    : '*'       
    | '/'       
    | '%'       
;

unary_op
    : '+'       { $$ = "POS"; }
    | '-'       { $$ = "NEG"; }
    | '!'       { $$ = "NOT"; }
;

PrimaryExpr
    : Operand
    | ConversionExpr
;

Operand
    : Literal { 
                $$ = $<s_val>1; 
            }
    | IDENT {
                node *symbol = lookup_symbol($<s_val>1);
                if(symbol !=NULL){
                    printf("IDENT (name=%s, address=%d)\n",$<s_val>1,symbol->addr);
                    $$=symbol->type;
                }else{
                    printf("error:%d: undefined: %s\n",yylineno+1,$<s_val>1);
                    $$ ="undefined";
                }
            }
    | '(' ExpressionStmt ')' { $$ = $<s_val>2;}
;

Literal
    : INT_LIT         { printf("INT_LIT %d\n", $<i_val>1); $$ = "int32"; }          
    | FLOAT_LIT       { printf("FLOAT_LIT %.6f\n", $<f_val>1); $$ = "float32"; }
    | TRUE            { printf("TRUE 1\n"); $$ = "bool"; }    
    | FALSE           { printf("FALSE 0\n"); $$ = "bool"; }     
    | '\"' STRING_LIT '\"'      { printf("STRING_LIT %s\n", $<s_val>2); $$ = "string"; }
;

ConversionExpr
	: Type '(' ExpressionStmt ')' {
		if(strcmp($<s_val>3, "int32") == 0){
    			printf("i");
	    	}
	    	else{
	    		printf("f");
	    	}
               printf("2");
               if(strcmp($<s_val>1, "int32") == 0){
    			printf("i\n");
	    	}
	    	else{
	    		printf("f\n");
	    	}
        }
;	

Block
    : '{' { create_symbol(); } StatementList '}'        { dump_symbol(); }
;

IfStmt
    : IF Condition Block
	| IF Condition Block ELSE IfStmt
	| IF Condition Block ELSE Block
;

Condition
	: ExpressionStmt{
        if(strcmp($<s_val>1,"bool")!=0){
        	printf("error:%d: non-bool (type %s) used as for condition\n",yylineno+1,$<s_val>1);
        }
    }
;	

ForStmt
    : FOR ExpressionStmt {
        if(strcmp($<s_val>2,"bool")!=0){
            printf("error:%d: non-bool (type %s) used as for condition\n",yylineno+1,$<s_val>2);
        }
    } Block
    | FOR ForClause Block
;

ForClause
    : SimpleStmt ';' ExpressionStmt ';' SimpleStmt
;

SwitchStmt
    : SWITCH ExpressionStmt Block
;

CaseStmt 
    : CASE NUM ':' Block
    | DEFAULT ':' Block
;

NUM
    : INT_LIT         { printf("case %d\n", $<i_val>1);}          
;

PrintStmt
	: PRINT '(' ExpressionStmt ')' { printf("PRINT %s\n", ($<s_val>3)); }
	| PRINTLN '(' ExpressionStmt ')' { printf("PRINTLN %s\n", ($<s_val>3)); }
;	

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    yylineno = 0;
    yyparse();

	printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    return 0;
}

static void create_symbol() {
    cur_Scope++;
    printf("> Create symbol table (scope level %d)\n", cur_Scope);
}

static void insert_symbol(char *name,char *type,char *func_sig,int scope,int yyl) {
    node *tmp;
    node *new_node=malloc(sizeof(node));
    new_node->name=name;
    new_node->type=type;
    new_node->addr=curAddr;
    new_node->lineno=yyl;
    new_node->func_sig=func_sig;
    new_node->next=NULL;
    if(!sym_table[scope]){
        sym_table[scope]=new_node;
    }
    else{
        tmp=sym_table[scope];
        while(tmp->next){
        	tmp=tmp->next;
        }
        tmp->next=new_node;
    }
    printf("> Insert `%s` (addr: %d) to scope level %d\n", name, curAddr, scope);
    curAddr=curAddr+1;
}

static void *lookup_symbol(char *name) {
    node *tmp2;
    int tmp;
	tmp=cur_Scope;
	while(tmp>=0){
	    tmp2=sym_table[tmp--];
	    while(tmp2 !=NULL){
	    	if(strcmp(tmp2->name,name)==0){
	    		return tmp2;
	    	}
	    	tmp2=tmp2->next;
	    }
	}
}

static void dump_symbol() {
    int i=0;
    node *now=sym_table[cur_Scope];

    printf("\n> Dump symbol table (scope level: %d)\n", cur_Scope);
    printf("%-10s%-10s%-10s%-10s%-10s%-10s\n",
           "Index", "Name", "Type", "Addr", "Lineno", "Func_sig");
    
    
    while(now!=NULL){
        node *tmp =now;
        printf("%-10d%-10s%-10s%-10d%-10d%-10s\n",i++,now->name,now->type,now->addr,now->lineno,now->func_sig);
        now = now->next;
    }
    sym_table[cur_Scope]=NULL;
    cur_Scope=cur_Scope-1;
    printf("\n");
}

static void check_type(char*a,char*b,int op){
	switch(op){
		case 0:
			if(strcmp(a,"bool")!=0 || strcmp(b,"bool")!=0 ){
                if(strcmp(a,"bool")!=0){
                    printf("error:%d: invalid operation: (operator LOR not defined on %s)\n",yylineno,a);
                }
                else{
                    printf("error:%d: invalid operation: (operator LOR not defined on %s)\n",yylineno,b);
                }
            }
            break;

        case 1:
            if(strcmp(a,"bool")!=0 || strcmp(b,"bool")!=0 ){
                if(strcmp(a,"bool")!=0){
                    printf("error:%d: invalid operation: (operator LAND not defined on %s)\n",yylineno,a);
                }
                else{
                    printf("error:%d: invalid operation: (operator LAND not defined on %s)\n",yylineno,b);
                }
            }
            break;
        case 4:
            if(strcmp(a,"int32")!=0 || strcmp(b,"int32")!=0 ){
                if(strcmp(a,"int32")!=0){
                    printf("error:%d: invalid operation: (operator REM not defined on %s)\n",yylineno+1,a);
                }
                else{
                    printf("error:%d: invalid operation: (operator REM not defined on %s)\n",yylineno+1,b);
                }
            }
    }
}
static int check_redclared(char* name){
    node *tmp = sym_table[cur_Scope];
    while (tmp != NULL) {
        if(strcmp(tmp->name, name) == 0) {
            return tmp->lineno;
        }
        tmp = tmp->next;
    }
    return -1;
}
