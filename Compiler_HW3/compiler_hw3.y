/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_hw_common.h" //Extern variables that communicate with lex

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    int yylex_destroy ();
	void yyerror (char const *s)
    {
        //printf("error:%d: %s\n", yylineno, s);
    }
    /* Used to generate code */
    /* As printf; the usage: CODEGEN("%d - %s\n", 100, "Hello world"); */
    /* We do not enforce the use of this macro */
    #define CODEGEN(...) \
        do { \
            for (int i = 0; i < g_indent_cnt; i++) { \
                fprintf(fout, "\t"); \
            } \
            fprintf(fout, __VA_ARGS__); \
        } while (0)
    /* Global variables */
    bool g_has_error = false;
    FILE *fout = NULL;
    int g_indent_cnt = 0;

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
    
    /* Symbol table function - you can add new functions if needed. */
    static void create_symbol();
    static node* insert_symbol(char *name,char *type,char *func_sig,int scope,int yyl);
    static void *lookup_symbol(char *name);
    static void dump_symbol();
    static void check_type(char*a,char*b,int op);
    static int check_redclared(char* name);
	
	node *assignedElement = NULL;
	int isFor=0;
	int Assign_is_used = 1;
    int Count_print = 0;
    char *number_type;
    static void print_Print_Println(int is_println, char *type);
    

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
%type <s_val> UnaryExpr PrimaryExpr Operand ConversionExpr Literal FuncOpen Type ForBegin

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : GlobalStatementList { dump_symbol();}
;

GlobalStatementList 
    : {create_symbol();} GlobalStatement GlobalStatementList 
    | 
;

GlobalStatement
    : PackageStmt NEWLINE
    | FunctionDeclStmt
    | NEWLINE
;


PackageStmt
    : PACKAGE IDENT{
        //printf("package: %s\n", $<s_val>2);
    }
;

FunctionDeclStmt
    : FuncOpen '(' ParameterList ')' ReturnType {
    	int check=check_redclared($<s_val>2);
	if(check<1){
		insert_symbol($<s_val>1,"func","()V",0,3);
	}
	else{
		    g_has_error=true;
	    }
    } FuncBlock {dump_symbol();}
;

FuncOpen
    : FUNC IDENT {
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
    :Type                                 
    | 
;

FuncBlock
    :'{' StatementList '}' 
;

ReturnStmt 
    : RETURN ExpressionStmt
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
        node *cur = insert_symbol($<s_val>2, $<s_val>3, "-",cur_Scope,yylineno);
        if (cur != NULL){
            if (1) {
                if (strcmp($<s_val>3, "int32") == 0)
                    CODEGEN("ldc 0\n");
                else if (strcmp($<s_val>3, "float32") == 0)
                    CODEGEN("ldc 0.0\n");
                else if (strcmp($<s_val>3, "string") == 0)
                    CODEGEN("ldc \"\"\n");
                else if (strcmp($<s_val>3, "bool") == 0)
                    CODEGEN("iconst_0\n");
            }
        }
        char *type = cur->type;
	    if (strcmp(type, "int32") == 0){
		    CODEGEN("istore %d	; store the result to %s\n\n", cur->addr,cur->name);
	    }
	    else if (strcmp(type, "float32") == 0){
		    CODEGEN("fstore %d 	; store the result to %s\n\n", cur->addr, cur->name);
	    }
	    else if (strcmp(type, "string") == 0){
		    CODEGEN("astore %d	; store \"\" to %s\n\n", cur->addr, cur->name);
	    }
	}
	else{
		g_has_error=true;
	}
    
}
| VAR IDENT Type '=' ExpressionStmt {
    int check=check_redclared($<s_val>2);
	if(check<1){
        node *cur = insert_symbol($<s_val>2, $<s_val>3, "-",cur_Scope,yylineno);
        if (cur != NULL){
            if (0) {
                if (strcmp($<s_val>3, "int32") == 0)
                    CODEGEN("ldc 0\n");
                else if (strcmp($<s_val>3, "float32") == 0)
                    CODEGEN("ldc 0.0\n");
                else if (strcmp($<s_val>3, "string") == 0)
                    CODEGEN("ldc \"\"\n");
                else if (strcmp($<s_val>3, "bool") == 0)
                    CODEGEN("iconst_0\n");
            }
        }
        char *type = cur->type;
	    if (strcmp(type, "int32") == 0){
		    CODEGEN("istore %d	; store the result to %s\n\n", cur->addr,cur->name);
	    }
	    else if (strcmp(type, "float32") == 0){
		    CODEGEN("fstore %d 	; store the result to %s\n\n", cur->addr, cur->name);
	    }
	    else if (strcmp(type, "string") == 0){
		    CODEGEN("astore %d	; store \"\" to %s\n\n", cur->addr, cur->name);
	    }
    }
	else{
		g_has_error=true;
	}
}
;

AssignmentStmt
    : LeftExpressionStmt { Assign_is_used = 0; }assign_op ExpressionStmt {
        Assign_is_used = 1;
        if(strcmp($<s_val>1,$<s_val>3)!=0){
            if(strcmp($<s_val>1,"undefined")!=0 && strcmp($<s_val>3,"undefined")!=0){
                g_has_error=true;
            }
            if(strcmp($<s_val>1,"undefined")==0 && strcmp($<s_val>3,"undefined")!=0){
                g_has_error=true;
            }
            if(strcmp(number_type,"int32")==0){
                if(strcmp($<s_val>3,"ASSIGN")==0){
                }
                else if(strcmp($<s_val>3,"ADD")==0){
                    CODEGEN("iadd\n");   
                }
                else if(strcmp($<s_val>3,"SUB")==0){
                    CODEGEN("isub\n");   
                }else if(strcmp($<s_val>3,"MUL")==0){
                	CODEGEN("imul\n"); 
                }else if(strcmp($<s_val>3,"QUO")==0){
                	CODEGEN("idiv\n"); 
                }else{
                	CODEGEN("irem\n"); 
                }
            }
            else{
                if(strcmp($<s_val>3,"ASSIGN")==0){
                }
                else if(strcmp($<s_val>3,"ADD")==0){
                    CODEGEN("fadd\n");   
                }
                else if(strcmp($<s_val>3,"SUB")==0){
                    CODEGEN("fsub\n");   
                }else if(strcmp($<s_val>3,"MUL")==0){
                	CODEGEN("fmul\n"); 
                }else if(strcmp($<s_val>3,"QUO")==0){
                	CODEGEN("fdiv\n"); 
                }else{
                	CODEGEN("frem\n"); 
                }
            }    
            if (strcmp($<s_val>1, "undefined") != 0){
                char *type = assignedElement->type;
                if (strcmp(type, "int32") == 0){
                    CODEGEN("istore %d	; store the result to %s\n\n", assignedElement->addr,assignedElement->name);
                }
                else if (strcmp(type, "float32") == 0){
                    CODEGEN("fstore %d 	; store the result to %s\n\n", assignedElement->addr, assignedElement->name);
                }
                else if (strcmp(type, "string") == 0){
                    CODEGEN("astore %d	; store \"\" to %s\n\n", assignedElement->addr, assignedElement->name);
                }
            }
        }
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
    : ExpressionStmt INC { 
        CODEGEN("ldc 1%s\n%cadd\n", ($<s_val>1[0]=='f')?".0":"", $<s_val>1[0]);
        char *type = assignedElement->type;
	    if (strcmp(type, "int32") == 0){
		    CODEGEN("istore %d	; store the result to %s\n\n", assignedElement->addr,assignedElement->name);
	    }
	    else if (strcmp(type, "float32") == 0){
		    CODEGEN("fstore %d 	; store the result to %s\n\n", assignedElement->addr, assignedElement->name);
	    }
	    else if (strcmp(type, "string") == 0){
		    CODEGEN("astore %d	; store \"\" to %s\n\n", assignedElement->addr, assignedElement->name);
	    }
    }
    | ExpressionStmt DEC { 
        CODEGEN("ldc 1%s\n%csub\n", ($<s_val>1[0]=='f')?".0":"", $<s_val>1[0]); 
        char *type = assignedElement->type;
	    if (strcmp(type, "int32") == 0){
		    CODEGEN("istore %d	; store the result to %s\n\n", assignedElement->addr,assignedElement->name);
	    }
	    else if (strcmp(type, "float32") == 0){
		    CODEGEN("fstore %d 	; store the result to %s\n\n", assignedElement->addr, assignedElement->name);
	    }
	    else if (strcmp(type, "string") == 0){
		    CODEGEN("astore %d	; store \"\" to %s\n\n", assignedElement->addr, assignedElement->name);
	    }
    }     
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
                                    $$ = "bool";
                                }
    | Term1
;

Term1
    : Term1 LAND Term2 {
                            check_type($<s_val>1,$<s_val>3,1);
                            $$ = "bool";
                        }
    | Term2
;

Term2
    : Term2 cmp_op Term3 { 
        if(strcmp($<s_val>1,"undefined")==0 && strcmp($<s_val>3,"undefined")!=0){
            g_has_error=true;
        }
        $$ = "bool";                 
        if(isFor==1){
            if(strcmp(number_type,"int32")==0){
                if(strcmp($<s_val>2,"LSS")==0){
                    CODEGEN("iadd\n");   
                }
                else{
                    CODEGEN("isub\n");   
                }
            }
            else{
                if(strcmp($<s_val>2,"LSS")==0){
                    CODEGEN("fadd\n");   
                }
                else{
                    CODEGEN("fsub\n");   
                }
            }
            CODEGEN("ifgt L_cmp_0\niconst_0\ngoto L_cmp_1\nL_cmp_0:\niconst_1\nL_cmp_1:\nifeq L_for_exit_0\n");	    
		}                  
    }
    | Term3
;

Term3
    : Term3 add_op Term4 {
        if (strcmp($<s_val>1, $<s_val>3) == 0)
            $$ = $<s_val>1;
        else if(strcmp($<s_val>1,"undefined")!=0 && strcmp($<s_val>3,"undefined")!=0){
            g_has_error=true;
        }
        if(strcmp(number_type,"int32")==0){
            if(strcmp($<s_val>2,"ADD")==0){
                CODEGEN("iadd\n");   
            }
            else{
                CODEGEN("isub\n");   
            }
        }
        else{
            if(strcmp($<s_val>2,"ADD")==0){
                CODEGEN("fadd\n");   
            }
            else{
                CODEGEN("fsub\n");   
            }
        }
    }
    | Term4
;

Term4
    : Term4 mul_op UnaryExpr {	
        if(strcmp($<s_val>2,"REM")==0){
            check_type($<s_val>1,$<s_val>3,4);
        }
        if (strcmp($<s_val>1, $<s_val>3) == 0)
            $$ = $<s_val>1;
        if(strcmp(number_type,"int32")==0){
            if(strcmp($<s_val>2,"MUL")==0){
                CODEGEN("imul\n");   
            }
            else if(strcmp($<s_val>2,"QUO")==0){
                CODEGEN("idiv\n");   
            }else{
                CODEGEN("irem\n"); 
            }
        }
        else{
            if(strcmp($<s_val>2,"MUL")==0){
                CODEGEN("fmul\n");   
            }
            else if(strcmp($<s_val>2,"QUO")==0){
                CODEGEN("fdiv\n");   
            }else{
                CODEGEN("frem\n"); 
            }
        }
    }
    | UnaryExpr
;

UnaryExpr
    : PrimaryExpr
    | unary_op UnaryExpr {
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
                    number_type = symbol->type;
                if (strcmp(number_type, "int32") == 0){
                    CODEGEN("iload %d ; load %s\n", symbol->addr,symbol->name);
                }
                else if (strcmp(number_type, "float32") == 0){
                    CODEGEN("fload %d ; load %s\n", symbol->addr,symbol->name);
                }
                else if (strcmp(number_type, "string") == 0){
                    CODEGEN("aload %d ; load %s\n", symbol->addr,symbol->name);
                }
                if (Assign_is_used) {
                    assignedElement = symbol;
                }
                $$=symbol->type;
                }else{
                    g_has_error=true;
                    $$ ="undefined";
                }
            }
    | '(' ExpressionStmt ')' { $$ = $<s_val>2;}
;

Literal
    : INT_LIT         { 
        CODEGEN("ldc %d\n", $<i_val>1);
        $$ = "int32"; 
    }          
    | FLOAT_LIT       { 
        CODEGEN("ldc %.6f\n", $<f_val>1);
        $$ = "float32"; 
    }
    | TRUE            { 
        CODEGEN("iconst_1\n");
        $$ = "bool"; 
    }    
    | FALSE           { 
        CODEGEN("iconst_0\n");
        $$ = "bool"; 
    }     
    | '\"' STRING_LIT '\"'      {
        CODEGEN("ldc \"%s\"\n", $<s_val>2);
        $$ = "string"; 
    }
;

ConversionExpr
	: Type '(' ExpressionStmt ')' {
        if(strcmp($<s_val>3, "int32") == 0){
            CODEGEN("i");	
        }
        else{
            CODEGEN("f");
        }
        CODEGEN("2");
        if(strcmp($<s_val>1, "int32") == 0){
            CODEGEN("i\n");
            number_type="int32";
        }
        else{
            CODEGEN("f\n");
            number_type="float32";
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
        	g_has_error=true;
        }
    }
;	

ForStmt
    : ForBegin ExpressionStmt {
        if(strcmp($<s_val>2,"bool")!=0){
            g_has_error=true;
        }  
    } Block { 
    	CODEGEN("goto L_for_begin_0\n");
    	CODEGEN("L_for_exit_0:\n");
    }
    | ForBegin ForClause Block { 
    	CODEGEN("goto L_for_begin_0\n");
    	CODEGEN("L_for_exit_0:\n");
    }
;

ForBegin
	:FOR {CODEGEN("L_for_begin_0:\n");isFor=1;}
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
    : INT_LIT         
;

PrintStmt
	: PRINT '(' ExpressionStmt ')' { 
        print_Print_Println(0, $<s_val>3);          
    }
	| PRINTLN '(' ExpressionStmt ')' {  
        print_Print_Println(1, $<s_val>3);
    }
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
    if (!yyin) {
        exit(1);
    }

    /* Codegen output init */
    char *bytecode_filename = "hw3.j";
    fout = fopen(bytecode_filename, "w");
    CODEGEN(".source hw3.j\n");
    CODEGEN(".class public Main\n");
    CODEGEN(".super java/lang/Object\n");
    CODEGEN(".method public static main([Ljava/lang/String;)V\n");
    CODEGEN(".limit stack 100\n");
    CODEGEN(".limit locals 100\n");

    /* Symbol table init */
    // Add your code

    yylineno = 0;
    yyparse();

    /* Symbol table dump */
    // Add your code
    CODEGEN("return\n");
    CODEGEN(".end method\n");

	//printf("Total lines: %d\n", yylineno);
    fclose(fout);
    fclose(yyin);

    /*if (g_has_error) {
        remove(bytecode_filename);
    }*/
    yylex_destroy();
    return 0;
}

static void create_symbol() {
    cur_Scope++;
}

static node* insert_symbol(char *name,char *type,char *func_sig,int scope,int yyl) {
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
    curAddr=curAddr+1;
    return new_node;
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
    node *now=sym_table[cur_Scope];
    while(now!=NULL){
        now = now->next;
    }
    sym_table[cur_Scope]=NULL;
    cur_Scope=cur_Scope-1;
}

static void check_type(char*a,char*b,int op){
	switch(op){
		case 0:
			if(strcmp(a,"bool")!=0 || strcmp(b,"bool")!=0 ){
                if(strcmp(a,"bool")!=0){
                    g_has_error=true;
                }
                else{
                    g_has_error=true;
                }
            }
            break;

        case 1:
            if(strcmp(a,"bool")!=0 || strcmp(b,"bool")!=0 ){
                if(strcmp(a,"bool")!=0){
                    g_has_error=true;
                }
                else{
                    g_has_error=true;
                }
            }
            break;
        case 4:
            if(strcmp(a,"int32")!=0 || strcmp(b,"int32")!=0 ){
                if(strcmp(a,"int32")!=0){
                    g_has_error=true;
                }
                else{
                    g_has_error=true;
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

static void print_Print_Println(int is_println, char *type) {

    if (strcmp(type, "bool") == 0) {
        CODEGEN("ifne L_cmp_%d\nldc \"false\"\ngoto L_cmp_%d\nL_cmp_%d:\n ldc \"true\"\nL_cmp_%d:\n"
            , Count_print*2, Count_print*2+1, Count_print*2, Count_print*2+1);
        Count_print++;
        print_Print_Println(is_println, "string");
    } else {
        CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        CODEGEN("swap\n");
        CODEGEN("invokevirtual java/io/PrintStream/print(");

        if (strcmp(type, "int32") == 0)
            CODEGEN("I");
        else if (strcmp(type, "float32") == 0)
            CODEGEN("F");
        else if (strcmp(type, "string") == 0)
            CODEGEN("Ljava/lang/String;");

        CODEGEN(")V\n");
        CODEGEN("\n");

        if (is_println)
            CODEGEN("ldc \"\\n\"\n");
            CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            CODEGEN("swap\n");
	        CODEGEN("invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
	        CODEGEN("\n"); 
    }
}
