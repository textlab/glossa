/* 
 *  IMS Open Corpus Workbench (CWB)
 *  Copyright (C) 1993-2006 by IMS, University of Stuttgart
 *  Copyright (C) 2007-     by the respective contributers (see file AUTHORS)
 * 
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2, or (at your option) any later
 *  version.
 * 
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 *  Public License for more details (in the file "COPYING", or available via
 *  WWW at http://www.gnu.org/copyleft/gpl.html).
 */

/* ****************************************************************** */
/* regular expression to DFA converter -- originally written by       */
/*                                        markh@csd4.csd.uwm.edu      */
/* Derived from the syntax:                                           */
/* Rule = (ID "=" Ex ",")* Ex.                                        */
/* Ex = "0" | "1" | ID | "(" Ex ")" | "[" Ex "]" | Ex "+" | Ex "*" |  */
/*       Ex Ex | Ex "|" Ex.                                           */
/* with the usual precedence rules.                                   */
/* ****************************************************************** */

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#include <assert.h>

#include "../cl/macros.h"

#include "eval.h"
#include "options.h"
#include "regex2dfa.h"


char *searchstr;

/* DATA STRUCTURES */
typedef unsigned char byte;

typedef struct symbol *Symbol;

typedef struct exp *Exp;

typedef struct equation *Equation;

typedef enum 
{ 
  SymX, ZeroX, OneX, AndX, OrX, StarX, PlusX, OptX 
} ExpTag;

typedef enum 
{ 
  RULE, EQU, PAR, OPT, OR, AND 
} StackTag;

typedef struct 
{ 
  StackTag Tag; 
  int Q; 
} StackCard;

typedef struct state 
{
  int Class, States, *SList;
  int Empty, Shifts;
  struct 
    { 
      Symbol LHS; 
      int RHS; 
    } *ShList;
} *State;
State STab = (State)NULL; 
int Ss;

/* THE SCANNER */
typedef enum 
{
  EndT, CommaT, RParT, RBrT, EqualT, BarT,
  ZeroT, OneT, IdenT, LParT, LBrT, PlusT, StarT
} Lexical;

typedef struct item 
{
  Symbol LHS; 
  int Size, *RHS;
} *Item;
Item IBuf = (Item)NULL; 
int Is, IMax;

struct exp 
{
  ExpTag Tag; 
  int Hash, Class; 
  Exp Tail;
  union 
    {
      Symbol Leaf; 
      int *Arg;
    } Body;
};

struct symbol 
{ 
  char *Name; 
  int Hash; 
  Symbol Next, Tail; 
};

char *Action[7] = 
{
  /*  $,)]=|01x([+*  */
  ".ABCH|&&&&&+*", /* RULE:       -> Exp $ */
  "I=BCH|&&&&&+*", /* EQU:   Exp  -> Exp "=" Exp $    */
  "DD)FH|&&&&&+*", /* PAR:   Exp  -> '(' Exp $ ')'    */
  "EEG]H|&&&&&+*", /* OPT:   Exp  -> '[' Exp $ ']'    */
  "vvvvv|&&&&&+*", /* OR:    Exp  -> Exp '|' Exp $    */
  "xxxxxx&&&&&+*"  /* AND:   Exp  -> Exp Exp $        */
};


char *LastW;

#define MAX_CHAR 0x4000
static char ChArr[MAX_CHAR];
char *ChP;

int LINE, ERRORS;

#define MAX_ERRORS 25

#define HASH_MAX 0x200
Symbol HashTab[HASH_MAX], FirstB, LastB;

#define NN 0x200
Exp ExpHash[NN];

#define EQU_EXTEND 0x200

struct equation 
{
  Exp Value; 
  int Hash;
  unsigned Stack:1;
};

Equation EquTab = (Equation)NULL;

int Equs, EquMax;

#define STACK_MAX 200
StackCard Stack[STACK_MAX], *SP;

int *XStack = NULL, Xs, XMax;

#define X_EXTEND 4

struct Equiv 
{ 
  State L, R; 
} *ETab = NULL; 

int Es, EMax;

int currpos;

static int GET(void)
{
  /* Thu Aug  3 13:25:13 1995 (oli) -- 
   * minor changes */

  unsigned char ch;

  ch = searchstr[currpos];

  if (ch == '\0')
    return EOF;
  else {
    currpos++;
    return ch;
  }
}

static void UNGET(int Ch)
{

  if (currpos != 0)
    --currpos;
}

static void ERROR(char *Format, ...) 
{

  va_list AP;
  
  fprintf(stderr, "[%d] ", LINE);
  va_start(AP, Format); vfprintf(stderr, Format, AP); va_end(AP);
  fputc('\n', stderr);
  if (++ERRORS == MAX_ERRORS) {
    fprintf(stderr, "regex2dfa: Reached the %d error limit.\n",
            MAX_ERRORS);
    exit(1);
  }
}

Lexical LEX(void) 
{

  int Ch;

  do {
    Ch = GET(); 
  } while (isspace(Ch));

  switch (Ch) {
  case EOF: 
    return EndT;
  case '|': 
    return BarT;
  case '(': 
    return LParT;
  case ')': 
    return RParT;
  case '[': 
    return LBrT;
  case ']': 
    return RBrT;
  case '0': 
    return ZeroT;
  case '1': 
    return OneT;
  case '*': 
    return StarT;
  case '+': 
    return PlusT;
  case '=': 
    return EqualT;
  case ',': 
    return CommaT;
  }

  if (isalpha(Ch) || Ch == '_' || Ch == '$') {
    for (LastW = ChP; isalnum(Ch) || Ch == '_' || Ch == '$'; ChP++) {
      if (ChP - ChArr == MAX_CHAR) {
        printf("Out of character space.\n");
        exit(1);
      }
      *ChP = Ch;
      Ch = GET();
    }
    if (Ch != EOF) 
      UNGET(Ch);
    if (ChP - ChArr == MAX_CHAR) {
      printf("Out of character space.\n");
      exit(1);
    }
    *ChP++ = '\0';
    return IdenT;
  } 
  else if (Ch == '"') {
    Ch = GET();
    for (LastW = ChP; Ch != '"' && Ch != EOF; ChP++) {
      if (ChP - ChArr == MAX_CHAR) {
        printf("Out of character space.\n");
        exit(1);
      }
      *ChP = Ch;
      Ch = GET();
    }
    if (Ch == EOF) {
      printf("Missing closing \".\n");
      exit(1);
    }
    if (ChP - ChArr == MAX_CHAR) {
      printf("Out of character space.\n");
      exit(1);
    }
    *ChP++ = '\0';
    return IdenT;
  } 
  else {
    ERROR("extra character %c", Ch); 
    return EndT;
  }
}

void *Allocate(unsigned Bytes) 
{
  void *X = cl_malloc(Bytes);
  return X;
}

void *Reallocate(void *X, unsigned Bytes) 
{
  
  X = cl_realloc(X, Bytes);
  return X;
}

char *CopyS(char *S) 
{
  char *NewS = (char *)Allocate(strlen(S) + 1);
  
  strcpy(NewS, S); 
  return NewS;
}

byte Hash(char *S) 
{

  int H; 
  char *T;
  
  for (H = 0, T = S; *T != '\0'; T++) 
    H = (H << 1) ^ *T;
  return H&0xff;
}

Symbol LookUp(char *S) 
{
  
  Symbol Sym; 
  byte H;
  
  for (H = Hash(S), Sym = HashTab[H]; Sym != 0; Sym = Sym->Next)
    if (strcmp(Sym->Name, S) == 0) 
      return Sym;
  Sym = (Symbol)Allocate(sizeof *Sym);
  Sym->Name = CopyS(S);
  Sym->Hash = H;
  Sym->Next = HashTab[H];
  HashTab[H] = Sym;
  Sym->Tail = 0;
  if (FirstB == 0) 
    FirstB = Sym; 
  else 
    LastB->Tail = Sym;
  return LastB = Sym;
}

int DUP(int A, int B) 
{

  long L, S;
  
  S = A + B;
  if (S < NN) 
    L = S*(S + 1)/2 + A;
  else {
    S = 2*(NN - 1) - S;
    A = NN - 1 - A;
    L = S*(S + 1)/2 + A;
    L = NN*NN - 1 - L;
  }
  return (int)(L/NN);
}

void Store(Symbol S, int Q) 
{

  int H = 0x100 + S->Hash; 
  Exp E;

  for (E = ExpHash[H]; E != 0; E = E->Tail)
    if (S == E->Body.Leaf) 
      break;
  if (E == 0) 
    {
      E = (Exp)Allocate(sizeof *E);
      E->Tag = SymX;
      E->Body.Leaf = S;
      E->Hash = H;
      E->Tail = ExpHash[H];
      ExpHash[H] = E;
    }
  E->Class = Q;
}

int MakeExp(int Q, ExpTag Tag, ...) 
{

  va_list AP; 
  Symbol Sym = NULL; 

  int H = 0; 
  byte Args = 0; 
  Exp HP, E; 
  int Q0 = 0, Q1 = 0;

  va_start(AP, Tag);

  switch (Tag) 
    {
    case SymX:
      Sym = va_arg(AP, Symbol);
      H = 0x100 + Sym->Hash; 
      Args = 0;
      for (HP = ExpHash[H]; HP != 0; HP = HP->Tail)
        if (Sym == HP->Body.Leaf) 
          {
            if (Q != -1 && Q != HP->Class) 
              EquTab[Q].Value = HP;
            return HP->Class;
          }
      break;
    case ZeroX: 
      H = 0; 
      goto MakeNullary;
    case OneX: 
      H = 1; 
      goto MakeNullary;
    MakeNullary:
      Args = 0; 
      HP = ExpHash[H];
      if (HP != 0) 
        {
          if (Q != -1 && Q != HP->Class) 
            EquTab[Q].Value = HP;
          return HP->Class;
        }
      break;
    case PlusX:
      Q0 = va_arg(AP, int); 
      H = 0x02 + EquTab[Q0].Hash*0x0a/0x200;
      goto MakeUnary;
    case StarX:
      Q0 = va_arg(AP, int); 
      H = 0x0c + EquTab[Q0].Hash*0x14/0x200;
      goto MakeUnary;
    case OptX:
      Q0 = va_arg(AP, int); 
      H = 0x20 + EquTab[Q0].Hash/0x10;
    MakeUnary:
      Args = 1;
      for (HP = ExpHash[H]; HP != 0; HP = HP->Tail)
        if (Q0 == HP->Body.Arg[0]) 
          {
            if (Q != -1 && Q != HP->Class) 
              EquTab[Q].Value = HP;
            return HP->Class;
          }
      break;
    case OrX:
      Q0 = va_arg(AP, int);
      Q1 = va_arg(AP, int);
      H = 0x40 + DUP(EquTab[Q0].Hash, EquTab[Q1].Hash)/8;
      goto MakeBinary;
    case AndX:
      Q0 = va_arg(AP, int);
      Q1 = va_arg(AP, int);
      H = 0x80 + DUP(EquTab[Q0].Hash, EquTab[Q1].Hash)/4;
    MakeBinary:
      Args = 2;
      for (HP = ExpHash[H]; HP != 0; HP = HP->Tail)
        if (Q0 == HP->Body.Arg[0] && Q1 == HP->Body.Arg[1]) 
          {
            if (Q != -1 && Q != HP->Class) 
              EquTab[Q].Value = HP;
            return HP->Class;
          }
      break;
    }
  va_end(AP);
  E = (Exp)Allocate(sizeof *E);
  E->Tag = Tag;
  if (Tag == SymX) 
    E->Body.Leaf = Sym;
  else 
    {
      E->Body.Arg = (int *) ((Args > 0) ? Allocate(Args*sizeof(int)) : NULL);
      if (Args > 0) 
        E->Body.Arg[0] = Q0;
      if (Args > 1) 
        E->Body.Arg[1] = Q1;
    }
  E->Hash = H;
  E->Tail = ExpHash[H];
  ExpHash[H] = E;
  if (Q == -1) 
    {
      if (Equs == EquMax) 
        {
          EquMax += EQU_EXTEND;
          EquTab = (Equation)Reallocate(EquTab, sizeof *EquTab * EquMax);
        }
      EquTab[Equs].Hash = H;
      EquTab[Equs].Stack = 0;
      Q = Equs++;
    }
  EquTab[Q].Value = E; 
  E->Class = Q; 
  return Q;
}

void PUSH(StackTag Tag, int Q) 
{

  if (SP >= Stack + STACK_MAX) 
    {
      ERROR("Expression too complex ... aborting.");
      exit(1);
    }
  SP->Tag = Tag;
  SP->Q = Q; 
  SP++;
}

/* Parser stack macros */
#define TOP ((SP - 1)->Tag)
#define POP() ((--SP)->Q)

/* the parser proper */
int Parse(void) 
{
  
  Lexical L; 
  Symbol ID = NULL; 
  int RHS; 
  
  int ignore_value;             /* ignore value of POP() macro */

  SP = Stack;
 LHS:
  L = LEX();
  if (L == IdenT) 
    {
      ID = LookUp(LastW); 
      L = LEX();
      if (L == EqualT) 
        {
          PUSH(EQU, -1);
          L = LEX();
        } 
      else 
        {
          PUSH(RULE, -1);
          RHS = MakeExp(-1, SymX, ID); 
          goto END;
        }
    } 
  else 
    PUSH(RULE, -1);
 EXP:
  switch (L) 
    {
    case LParT: 
      PUSH(PAR, -1); 
      L = LEX(); 
      goto EXP;
    case LBrT: 
      PUSH(OPT, -1); 
      L = LEX(); 
      goto EXP;
    case ZeroT: 
      RHS = MakeExp(-1, ZeroX); 
      L = LEX(); 
      goto END;
    case OneT: 
      RHS = MakeExp(-1, OneX); 
      L = LEX(); 
      goto END;
    case IdenT: 
      RHS = MakeExp(-1, SymX, LookUp(LastW)); 
      L = LEX(); 
      goto END;
    default: 
      ERROR("Corrupt expression."); 
      return -1;
    }
  
 END:
  switch (Action[TOP][L]) 
    {
    case 'A': 
      ERROR("Extra ','"); 
      exit(1);
    case 'B': 
      ERROR("Unmatched ).");  
      L = LEX(); 
      goto END;
    case 'C': 
      ERROR("Unmatched ].");  
      L = LEX(); 
      goto END;
    case 'D': 
      ERROR("Unmatched (."); 
      ignore_value = POP();
      goto END;
    case 'E': 
      ERROR("Unmatched [."); 
      goto MakeOpt;
    case 'F': 
      ERROR("( ... ]."); 
      ignore_value = POP(); 
      L = LEX(); 
      goto END;
    case 'G': 
      ERROR("[ ... )."); 
      L = LEX(); 
      goto MakeOpt;
    case 'H': 
      ERROR("Left-hand side of '=' must be symbol."); 
      exit(1);
    case 'I': 
      ERROR("Missing evaluation."); 
      exit(1);
    case '.': 
      ignore_value = POP(); 
      return RHS;
    case ')': 
      ignore_value = POP(); 
      L = LEX(); 
      goto END;
    case ']':
      L = LEX();
    MakeOpt:
      ignore_value = POP(); 
      RHS = MakeExp(-1, OptX, RHS);
      goto END;
    case '=': 
      Store(ID, RHS); 
      ignore_value = POP(); 
      goto LHS;
    case 'v': 
      RHS = MakeExp(-1, OrX, POP(), RHS); 
      goto END;
    case 'x': 
      RHS = MakeExp(-1, AndX, POP(), RHS); 
      goto END;
    case '*': 
      RHS = MakeExp(-1, StarX, RHS); 
      L = LEX(); 
      goto END;
    case '+': 
      RHS = MakeExp(-1, PlusX, RHS); 
      L = LEX(); 
      goto END;
    case '|': 
      PUSH(OR, RHS); L = LEX(); 
      goto EXP;
    case '&': 
      PUSH(AND, RHS); 
      goto EXP;
  }

  assert(0 && "Not reached");
  return 0;
}

void PushQ(int Q) 
{

  if (EquTab[Q].Stack) 
    return;
  if (Xs == XMax)
    {
      XMax += X_EXTEND;
      XStack = Reallocate(XStack, sizeof *XStack * XMax);
    }
  XStack[Xs++] = Q; 
  EquTab[Q].Stack = 1;
}

void PopQ(void) 
{

   int Q = XStack[--Xs];

   EquTab[Q].Stack = 0;
}


int AddState(int States, int *SList) 
{

  int D, I; 
  State DP;

  for (D = 0; D < Ss; D++) 
    {
      DP = &STab[D];
      if (States != DP->States) 
        continue;
      for (I = 0; I < States; I++)
        if (SList[I] != DP->SList[I]) 
          break;
      if (I >= States) 
        { 
          free(SList); 
          return D; 
        }
    }
  /* Brilliant ... the Reallocate() below might move the state table around in memory if it cannot
     be expanded in place, breaking any pointers into the table held in local variables of the calling
     function.  Fortunately, AddState() is only called from FormState() in a loop that modifies 
     "embedded" variables, so that this bug only surfaces if the original memory location is overwritten
     immediately (while the loop is still running).  It can be triggered reliably by the query
         ([pos = "IN|TO"] [pos = "DT.*"]? [pos = "JJ.*"]* [pos = "N.*"]+){3};
     on a PowerPC G4 running Mac OS X 10.4 (God knows why it happens in this configuration).
     To avoid the problem, local pointers into STab[] should be updated after every call to AddState(). */
  if ((Ss&7) == 0) 
    STab = Reallocate(STab, sizeof *STab * (Ss + 8));
  STab[Ss].Class = Ss;
  STab[Ss].States = States;
  STab[Ss].SList = SList;
  return Ss++;
}


void AddBuf(Symbol LHS, int Q) 
{

  int Diff, I, J, S, T; 
  Item IP; 
  char *Name = LHS->Name;

  for (I = 0; I < Is; I++) 
    {
      Diff = strcmp(IBuf[I].LHS->Name, Name);
      if (Diff == 0) 
        goto FOUND;
      if (Diff > 0) break;
    }
  if (Is >= IMax)
    { 
      IMax += 8;
      IBuf = Reallocate(IBuf, sizeof *IBuf * IMax);
    }
  for (J = Is++; J > I; J--) 
    IBuf[J] = IBuf[J - 1];
  IBuf[I].LHS = LHS, IBuf[I].Size = 0, IBuf[I].RHS = 0;

 FOUND:
  IP = &IBuf[I];
  for (S = 0; S < IP->Size; S++) 
    {
      if (IP->RHS[S] == Q) 
        return;
      if (IP->RHS[S] > Q) 
        break;
    }
  if ((IP->Size&7) == 0)
    IP->RHS = Reallocate(IP->RHS, sizeof *IP->RHS * (IP->Size + 8));
  for (T = IP->Size++; T > S; T--) 
    IP->RHS[T] = IP->RHS[T - 1];
  IP->RHS[S] = Q;
}

void FormState(int Q) 
{

  int I, S, S1, X; 
  int qX, Q1, Q2;
  int A, B;
  State SP;
  Exp E, E1;

  IBuf = NULL;
  IMax = 0;
  STab = NULL;
  Ss = 0; 
  AddState(1, &Q);

  for (S = 0; S < Ss; S++) 
    {
      SP = &STab[S];
      for (Xs = 0, S1 = 0; S1 < SP->States; S1++) 
        PushQ(SP->SList[S1]);
      for (SP->Empty = 0, Is = 0, X = 0; X < Xs; X++) 
        {
          qX = XStack[X];
        EVALUATE:
          E = EquTab[qX].Value;
          switch (E->Tag) 
            {
            case SymX: 
              AddBuf(E->Body.Leaf, MakeExp(-1, OneX)); 
              break;
            case OneX: 
              SP->Empty = 1; 
              break;
            case ZeroX: 
              break;
            case OptX:
              Q1 = E->Body.Arg[0];
              MakeExp(qX, OrX, MakeExp(-1, OneX), E->Body.Arg[0]);
              goto EVALUATE;
            case PlusX:
              Q1 = E->Body.Arg[0];
              MakeExp(qX, AndX, Q1, MakeExp(-1, StarX, Q1));
              goto EVALUATE;
            case StarX:
              Q1 = E->Body.Arg[0];
              MakeExp(qX, OrX, MakeExp(-1, OneX), MakeExp(-1, PlusX, Q1));
              goto EVALUATE;
            case OrX:
              Q1 = E->Body.Arg[0]; 
              Q2 = E->Body.Arg[1];
              PushQ(Q1);
              PushQ(Q2);
              break;
            case AndX: 
              Q1 = E->Body.Arg[0], Q2 = E->Body.Arg[1];
              E1 = EquTab[Q1].Value;
              switch (E1->Tag) 
                {
                case SymX: 
                  AddBuf(E1->Body.Leaf, Q2); 
                  break;
                case OneX: 
                  EquTab[qX].Value = EquTab[Q2].Value; 
                  goto EVALUATE;
                case ZeroX: 
                  MakeExp(qX, ZeroX); 
                  break;
                case OptX:
                  A = E1->Body.Arg[0];
                  MakeExp(qX, OrX, Q2, MakeExp(-1, AndX, A, Q2));
                  goto EVALUATE;
                case PlusX:
                  A = E1->Body.Arg[0];
                  MakeExp(qX, AndX, A, MakeExp(-1, OrX, Q2, qX));
                  goto EVALUATE;
                case StarX:
                  A = E1->Body.Arg[0];
                  MakeExp(qX, OrX, Q2, MakeExp(-1, AndX, A, qX));
                  goto EVALUATE;
                case OrX:
                  A = E1->Body.Arg[0], B = E1->Body.Arg[1];
                  MakeExp(qX, OrX,
                          MakeExp(-1, AndX, A, Q2), MakeExp(-1, AndX, B, Q2));
                  goto EVALUATE;
                case AndX:
                  A = E1->Body.Arg[0], B = E1->Body.Arg[1];
                  MakeExp(qX, AndX, A, MakeExp(-1, AndX, B, Q2));
                  goto EVALUATE;
                }
            }
        }
      while (Xs > 0) 
        PopQ();
      SP->Shifts = Is;
      SP->ShList = Allocate(sizeof *SP->ShList * Is);
      for (I = 0; I < Is; I++) 
        {
          int rhs_state = -1;
          SP->ShList[I].LHS = IBuf[I].LHS;
          rhs_state = AddState(IBuf[I].Size, IBuf[I].RHS);
          SP = &STab[S];        /* AddState() might have reallocated state table -> update pointer */
          SP->ShList[I].RHS = rhs_state;
        }
    }
  free(IBuf);
  IBuf = 0;
  Is = IMax = 0;
}

void AddEquiv(int L, int R) 
{
  int E; 
  State SL, SR;

  L = STab[L].Class;
  R = STab[R].Class;

  if (L == R) return;
  if (L > R)
    { 
      L ^= R;
      R ^= L;
      L ^= R;
    }

  SL = &STab[L];
  SR = &STab[R];

  for (E = 0; E < Es; E++)
    if (SL == ETab[E].L && SR == ETab[E].R) 
      return;
  if (Es >= EMax)
    {
      EMax += 8;
      ETab = Reallocate(ETab, sizeof *ETab * EMax);
    }
  ETab[Es].L = SL;
  ETab[Es].R = SR;
  Es++;
}

void MergeStates(void) 
{

  int Classes, S, S1, E, Sh; 
  State SP, SP1, QL, QR;

  ETab = 0;
  EMax = 0;

  for (S = 0; S < Ss; S++) 
    {
      SP = &STab[S];
      if (SP->Class != S) 
        continue;
      for (S1 = 0; S1 < S; S1++) 
        {
          SP1 = &STab[S1];
          if (SP1->Class != S1) 
            continue;
          Es = 0;
          AddEquiv(S, S1);
          for (E = 0; E < Es; E++) 
            {
              QL = ETab[E].L;
              QR = ETab[E].R;
              if (QL->Empty != QR->Empty || QL->Shifts != QR->Shifts)
                goto NOT_EQUAL;
              for (Sh = 0; Sh < QL->Shifts; Sh++)
                if (QL->ShList[Sh].LHS != QR->ShList[Sh].LHS) 
                  goto NOT_EQUAL;
              for (Sh = 0; Sh < QL->Shifts; Sh++)
                AddEquiv(QL->ShList[Sh].RHS, QR->ShList[Sh].RHS);
            }
          /* EQUAL: */ break;
        NOT_EQUAL: continue;
        }
      if (S1 < S) for (E = 0; E < Es; E++) 
        {
          State QL = ETab[E].L;
          QR = ETab[E].R;
          QR->Class = QL->Class;
        }
    }
  for (Classes = 0, S = 0; S < Ss; S++) 
    {
      SP = &STab[S];
      SP->Class = (SP->Class == S) ? Classes++ : STab[SP->Class].Class;
    }
}

void
WriteStates(void)
{

  int S, Sh, Classes, C; 
  State SP;

  for (S = Classes = 0; S < Ss; S++) 
    {
      SP = &STab[S];
      if (SP->Class != Classes) 
        continue;
      Classes++;
      printf("s%d =", SP->Class);
      if (SP->Empty) 
        {
          printf(" fin");
          if (SP->Shifts > 0) 
            printf(" |");
        }
      for (Sh = 0; Sh < SP->Shifts; Sh++) 
        {
          C = SP->ShList[Sh].RHS;
          if (Sh > 0) 
            printf(" |");
          printf(" %s s%d", SP->ShList[Sh].LHS->Name, STab[C].Class);
        }
      putchar('\n');
    }
}

void init_dfa(DFA *dfa)
{
  assert(dfa);

  dfa->TransTable = (int **)NULL;
  dfa->Final = (Boolean *)NULL;
  dfa->Max_States = dfa->Max_Input = 0;
}

void free_dfa(DFA *dfa)
{
  
  int i;

  assert(dfa);

  for(i = 0; i < dfa->Max_States; i++) {
    free(dfa->TransTable[i]);
    dfa->TransTable[i] = (int *)NULL;
  }

  free(dfa->TransTable);
  dfa->TransTable = (int **)NULL;

  free(dfa->Final);
  dfa->Final = (Boolean *)NULL;

  dfa->Max_States = 0;
  dfa->Max_Input = 0;
}

void
show_complete_dfa(DFA dfa)
{
  int i, j;

  for (i = 0; i < dfa.Max_States; i++) {
    printf("s%d", i);
    if (dfa.Final[i])
      printf("(final)");
    else
      putchar('\t');
    for (j = 0; j < dfa.Max_Input; j++)
      {
        printf("\t%d -> ", j);
        if (dfa.TransTable[i][j] == dfa.E_State)
          printf("E\t");
        else
          printf("s%d,",dfa.TransTable[i][j]);
      }
    putchar('\n');
  }
}

void
init(void)
{
  int i;

  if (STab)
    free(STab);
  STab = NULL;
  if (IBuf)
    free(IBuf);
  IBuf = NULL;
  if (EquTab)
    free(EquTab);
  EquTab = NULL;
  if (XStack)
    free(XStack);
  XStack = NULL;
  if (ETab)
    free(ETab);
  ETab = NULL;

  for (i = 0; i < HASH_MAX; i++) {
    if (HashTab[i])
      free(HashTab[i]);
    HashTab[i] = NULL;
  }

  for (i = 0; i < NN; i++) {
    if (ExpHash[i])
      free(ExpHash[i]);
    ExpHash[i] = NULL;
  }
    
  ChP = ChArr;
  LINE = 1;
  ERRORS = 0;
  FirstB = NULL;
  Equs = 0;
  EquMax = 0;
  Xs = 0;
  XMax = 0;
  Ss = 0;
  currpos = 0;
}

/**
 * Converts a regular expression to a DFA.
 *
 * @param rxs         The regular expression.
 * @param automaton   Pointer to the DFA to write to.
 */
void
regex2dfa(char *rxs, DFA *automaton)
{
  int Q, i, j;
  int S, Sh, Classes, C; 
  State SP;

  searchstr = rxs;

  init();

  Q = Parse();
  
  if (ERRORS > 0) 
    fprintf(stderr, "%d error(s)\n", ERRORS);
  if (Q == -1) 
    exit(1);
  FormState(Q);
  MergeStates(); 

  automaton->Max_States = Ss;
  automaton->Max_Input = Environment[eep].MaxPatIndex + 1;
  automaton->E_State = automaton->Max_States;

  if (show_dfa)
    WriteStates();

  /* allocate memory for the transition table and initialize it. */
  automaton->TransTable = 
    (int **)Allocate(sizeof(int *) * automaton->Max_States);
  for (i = 0; i < Ss; i++)
    {
      automaton->TransTable[i] = 
        (int *)Allocate(sizeof(int) * automaton->Max_Input);
      for (j = 0; j < automaton->Max_Input; j++)
        automaton->TransTable[i][j] = automaton->E_State;
    }

  /* allocate memory for the table of final states. */
  automaton->Final = (Boolean *)Allocate(sizeof(Boolean) * (Ss + 1));

  /* initialize the table of final states. */
  for (i = 0; i <= automaton->Max_States; i++)
    automaton->Final[i] = False;

  for (S = Classes = 0; S < Ss; S++) 
    {
      SP = &STab[S];
      if (SP->Class != Classes) 
        continue;
      Classes++;
      if (SP->Empty) 
        automaton->Final[SP->Class] = True;
      for (Sh = 0; Sh < SP->Shifts; Sh++) 
        {
          C = SP->ShList[Sh].RHS;
          automaton->TransTable[SP->Class][atoi(SP->ShList[Sh].LHS->Name)] = 
            STab[C].Class;
        }
    }
}
