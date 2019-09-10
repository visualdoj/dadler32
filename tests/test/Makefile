default : build run;

ifeq (,$(wildcard Makefile.node))
  DOJ_ENVIRONMENT :=
  UNITS_DIR := ../..
  PROGNAME := test
ifeq ($(OS),Windows_NT)
EXE_NAME := $(PROGNAME).exe
RUN_CMD := $(EXE_NAME)
clean :
	del *.map *.ppu *.o *.s *.out $(PROGNAME).exe
else
EXE_NAME := $(PROGNAME)
RUN_CMD := ./$(EXE_NAME)
clean :
	rm *.map *.ppu *.o *.s *.out $(PROGNAME)
endif
  FPC := fpc
  FPC_OPTIONS := -O3 -Oodfa -Sew -g -gl -al -an -ar -at -vq -Xm -CX -XX -Xs

fpcprog : $(EXE_NAME);
$(EXE_NAME) : $(UNITS_DIR)/dadler32.pas test.pas
	$(FPC) $(FPC_OPTIONS) -FU. -Fu$(UNITS_DIR) test.pas
progrun :
	@$(RUN_CMD) 2>&1 && echo OK
else
  include Makefile.node
endif

build   : fpcprog;
run     : progrun;
