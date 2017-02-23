/* Part of LogicMOO Base Logicmoo Path Setups
% ===================================================================
% File '$FILENAME.pl'
% Purpose: An Implementation in SWI-Prolog of certain debugging tools
% Maintainer: Douglas Miles
% Contact: $Author: dmiles $@users.sourceforge.net ;
% Version: '$FILENAME.pl' 1.0.0
% Revision: $Revision: 1.1 $
% Revised At:  $Date: 2002/07/11 21:57:28 $
% Licience: LGPL
% ===================================================================
*/
% File: /opt/PrologMUD/pack/logicmoo_base/prolog/logicmoo/util/logicmoo_util_filesystem.pl
:- module(logicmoo_util_filesystem,
          [ 
            add_library_search_path/2,
            add_file_search_path/2,
            add_to_search_path/2,
            add_to_search_path/3,
            add_to_search_path_first/2,
            add_to_search_path_last/2,
            atom_concat_safe/3,
            atom_ensure_endswtih/3,
            canonical_pathname/2,
            clip_dir_sep/2,
            concat_paths/2,
            concat_paths/3,
            current_dirs/1,
            current_dirs0/1,
            maybe_add_import_module/3,
            current_filedir/1,
            current_filesource/1,
            enumerate_files/2,
            enumerate_files0/2,
            enumerate_files00/2,
            enumerate_files01/2,
            enumerate_files1/2,
            enumerate_files2/2,
            enumerate_m_files/3,
            exists_directory_safe/1,
            exists_dirf/1,
            exists_file_or_dir/1,
            exists_file_safe/1,
            expand_file_name_safe/2,
            expand_wfm/2,
            filematch/2,
            filematch3/3,
            filematch_ext/3,
            global_pathname/2,
            if_file_exists/1,
            if_startup_script/0,
            in_include_file/0,
            if_startup_script/1,
            in_search_path/2,
            is_directory/1,
            join_path/3,
            join_path_if_needed/3,
            local_directory_search_combined/1,
            local_directory_search_combined2/1,
            locally_to_dir/2,
            my_absolute_file_name/2,
            normalize_path/2,
            os_to_prolog_filename/2,
            prolog_file_dir/1,
            prolog_file_dir/2,
            relative_pathname/2,
            remove_search_path/2,
            resolve_dir/2,
            time_file_safe/2,
            to_filename/2,
            upcase_atom_safe/2,
            with_filematch/1,
            with_filematches/1


            
          ]).


:- multifile
        local_directory_search/1.
:- meta_predicate
        add_to_search_path(2, ?, ?),
        enumerate_files(:, -),
        filematch(:, -),
        filematch_ext(+, :, -),
        if_file_exists(:),
        if_startup_script(0),
        with_filematch(0).
:- module_transparent
        add_library_search_path/2,
        add_file_search_path/2,
        add_to_search_path/2,
        add_to_search_path_first/2,
        add_to_search_path_last/2,
        atom_concat_safe/3,
        atom_ensure_endswtih/3,
        canonical_pathname/2,
        clip_dir_sep/2,
        concat_paths/2,
        concat_paths/3,
        current_dirs/1,
        current_dirs0/1,
        current_filedir/1,
        current_filesource/1,
        enumerate_files0/2,
        enumerate_files00/2,
        enumerate_files01/2,
        enumerate_files1/2,
        enumerate_files2/2,
        enumerate_m_files/3,
        exists_directory_safe/1,
        exists_dirf/1,
        exists_file_or_dir/1,
        exists_file_safe/1,
        expand_file_name_safe/2,
        expand_wfm/2,
        filematch3/3,
        global_pathname/2,
        if_startup_script/0,
        in_search_path/2,
        is_directory/1,
        join_path/3,
        join_path_if_needed/3,
        local_directory_search/1,
        local_directory_search_combined/1,
        local_directory_search_combined2/1,
        locally_to_dir/2,
        my_absolute_file_name/2,
        normalize_path/2,
        os_to_prolog_filename/2,
        prolog_file_dir/1,
        prolog_file_dir/2,
        relative_pathname/2,
        remove_search_path/2,
        time_file_safe/2,
        to_filename/2,
        upcase_atom_safe/2,
        maybe_add_import_module/3,
        with_filematches/1.
:- dynamic
        local_directory_search/1.

:- set_module(class(library)).
:- use_module(library(dialect)).


:- ensure_loaded(library(no_repeats)).

:- if(exists_source(library(filesex))).
%:- set_prolog_flag(generate_debug_info, true).=
:- '@'( ensure_loaded(library(filesex)), 'user').

:-endif.


%% resolve_dir( ?Dir, ?Dir) is semidet.
%
% Resolve Dir.
%
resolve_dir(Dir,Dir):- is_absolute_file_name(Dir),!,exists_directory(Dir),!.
resolve_dir(Path,Dir):- 
  (prolog_load_context(directory,SDir);
   (prolog_load_context(file,File),file_directory_name(File,SDir));
   (prolog_load_context(source,File),file_directory_name(File,SDir));
   (catch((current_source_file(F),to_filename(F,File),atom(File)),_,fail),file_directory_name(File,SDir));
    working_directory(SDir,SDir)),exists_directory(SDir),
    catch(absolute_file_name(Path,Dir,[relative_to(SDir),access(read),file_errors(fail),file_type(directory)]),_,fail),
    exists_directory(Dir).


%%	add_file_search_path(+Alias, +WildCard) is det.
%
%	Create an alias when it is missing
%
%	  ==
%	  :- add_file_search_path(all_utils, '../*/util/').
%	  ==

add_file_search_path(Name,Path):-  must(resolve_dir(Path,Dir)),
   is_absolute_file_name(Dir), (( \+ user:file_search_path(Name,Dir)) ->asserta(user:file_search_path(Name,Dir));true).
   
%%	add_library_search_path(+Dir, +Patterns:list(atom)) is det.
%
%	Create an autoload index INDEX.pl for  Dir by scanning all files
%	that match any of the file-patterns in Patterns. Typically, this
%	appears as a directive in MKINDEX.pl.  For example:
%
%	  ==
%	  :- add_library_search_path('../*/util/',[ 'logicmoo_util_*.pl']).
%	  ==
%

add_library_search_path(Path,Masks):- 
   forall(resolve_dir(Path,Dir), 
      (make_library_index(Dir, Masks), 
        (user:library_directory(Dir) -> true ; (asserta(user:library_directory(Dir)), 
          reload_library_index)))).




maybe_add_import_module(A,B):-maybe_add_import_module(A,B,start).

%TODO
maybe_add_import_module(_From,_To,_):- !.

maybe_add_import_module(From,To,_):- (call(ereq,mtCycL(From)); call(ereq,mtCycL(To))),!.
maybe_add_import_module(From,To,_):- default_module(From,To),!.
maybe_add_import_module(user,_,start):-!.
maybe_add_import_module(From,To,Start):-  
   maybe_delete_import_module(To,From),
   catch(add_import_module(From,To,Start),E,writeln(E=add_import_module(From,To,Start))).

maybe_delete_import_module(_From,To):- To = user,!.
maybe_delete_import_module(_From,To):- To = system,!.


:- meta_predicate(with_filematch(0)).
%= 	 	 

%% with_filematch( :GoalG) is semidet.
%
% Using Filematch.
%
with_filematch(G):- expand_wfm(G,GG),!,GG.

%= 	 	 

%% with_filematches( ?G) is semidet.
%
% Using Filematches.
%
with_filematches(G):- forall(expand_wfm(G,GG),GG).


%= 	 	 

%% expand_wfm( ?G, ?GG) is semidet.
%
% Expand Wfm.
%
expand_wfm(G,GG):- once((sub_term(Sub, G),compound(Sub),Sub=wfm(F))),
   (filematch(F,M),subst(G,wfm(F),M,GG),y_must(with_filematch(G), (G\=@=GG))).


:- export(current_filesource/1).
:- export(current_filedir/1).

%= 	 	 

%% current_filedir( ?D) is semidet.
%
% Current Filedir.
%
current_filedir(D):- no_repeats(D,(current_filesource(F),file_directory_name(F,D))).

%= 	 	 

%% current_filesource( ?F) is semidet.
%
% Current Filesource.
%
current_filesource(F):-source_location(F,_).
current_filesource(F):-seeing(X),is_stream(X),stream_property(X,file_name(F)).
current_filesource(F):-stream_property(_,file_name(F)).

:- export(filematch/2).
:- meta_predicate(filematch(:,-)).

%= 	 	 

%% filematch( ?Spec, -Result) is semidet.
%
% Filematch.
%
filematch(Spec,Result):-  enumerate_files(Spec,Result).


:- thread_local(t_l:file_ext/1).
:- meta_predicate(filematch_ext(+,:,-)).
:- export(filematch_ext/3).

%= 	 	 

%% filematch_ext( +Ext, ?FileIn, -File) is semidet.
%
% Filematch Ext.
%
filematch_ext(Ext,FileIn,File):-
  locally(t_l:file_ext(Ext),filematch(FileIn,File)).

:- meta_predicate(enumerate_files(:,-)).
:- export(enumerate_files/2).

%= 	 	 

%% enumerate_files( ?CALL1, -Result) is semidet.
%
% Enumerate Files.
%
enumerate_files(_:Spec,Result):- call((atom(Spec),is_absolute_file_name(Spec),(exists_file(Spec);exists_directory(Spec)),prolog_to_os_filename(Result,Spec))),!.
enumerate_files(M:Spec,Result):-
   call((no_repeats_old([Result],((enumerate_m_files(M,Spec,NResult),once((normalize_path(NResult,Result)->exists_file_or_dir(Result)))))))).

:- meta_predicate(enumerate_files(:,-)).
:- export(enumerate_m_files/3).

%= 	 	 

%% enumerate_m_files( ?M, ?Mask, ?File1) is semidet.
%
% Enumerate Module Files.
%
enumerate_m_files(user, Mask,File1):-!,enumerate_files0(Mask,File1).
enumerate_m_files(M, Mask,File1):- enumerate_files0(Mask,File1)*->true;enumerate_m_files_mscoped(M, Mask,File1).


%= 	 	 

%% enumerate_m_files_mscoped( ?M, ?Mask, ?File1) is semidet.
%
% Enumerate Module Files Mscoped.
%
enumerate_m_files_mscoped(M, Mask,File1):- 
  findall(t_l:search_first_dir(Dir),
   (((M\=user,user:file_search_path(M,SP),expand_file_search_path(SP,Dir));((module_property(M, file(File)),directory_file_path(Dir,_,File)))),
   exists_directory(Dir)),List),
  list_to_set(List,Set),
  locally(Set,enumerate_files0(Mask,File1)).

:- export(enumerate_files0/2).

%= 	 	 

%% enumerate_files0( ?Mask, ?File1) is semidet.
%
% Enumerate Files Primary Helper.
%
enumerate_files0(Mask,File1):- absolute_file_name(Mask,X,[expand(true),file_errors(fail),solutions(all)]),expand_file_name(X,Y),Y\==[],member(File1,Y).
enumerate_files0(Mask,File1):- one_must(filematch3('./',Mask,File1),(current_filedir(D),filematch3(D,Mask,File1))).
enumerate_files0(Spec,Result):- enumerate_files00(Spec,Result).
enumerate_files0(Spec,Result):- to_filename(Spec,Result).
enumerate_files0(Mask,File1):-  (current_dirs(D),filematch3(D,Mask,File1)).

enumerate_files01(_Mask,_File1):-fail.


%= 	 	 

%% enumerate_files00( ?Spec, ?Result) is semidet.
%
% Enumerate Files Primary Helper Primary Helper.
%
enumerate_files00(Spec,Result):- expand_file_name_safe(Spec,ResultList),ResultList\=[],!,member(NResult,ResultList),enumerate_files2(NResult,Result).
enumerate_files00(Spec,Result):- enumerate_files1(Spec,M),enumerate_files2(M,Result).


:- export(filematch3/3).

%= 	 	 

%% filematch3( ?RelativeTo, ?Mask, ?File1) is semidet.
%
% Filematch3.
%
filematch3(RelativeTo,Mask,File1):-
   findall(Ext,t_l:file_ext(Ext),EXTs),flatten([EXTs,'','pl.in'],Flat),
   absolute_file_name(Mask,File1Matched,[extensions(Flat),
   expand(true),file_errors(fail),solutions(all),relative_to(RelativeTo),access(read)]),expand_file_name(File1Matched,File1S),member(File1,File1S).
filematch3(RelativeTo,Mask,File1):-absolute_file_name(Mask,File1Matched,[file_type(directory),
   expand(true),file_errors(fail),solutions(all),relative_to(RelativeTo),access(read)]),expand_file_name(File1Matched,File1S),member(File1,File1S).

:- export(enumerate_files2/2).

%= 	 	 

%% enumerate_files2( ?Spec, ?Result) is semidet.
%
% Enumerate Files Extended Helper.
%
enumerate_files2(Spec,Result):-sub_atom(Spec,_,1,_,'*') -> enumerate_files1(Spec,Result);Spec=Result.

:- export(enumerate_files1/2).

%= 	 	 

%% enumerate_files1( :TermAtom, ?Result) is semidet.
%
% Enumerate Files Secondary Helper.
%
enumerate_files1(Atom,Result):- atomic(Atom),\+(is_absolute_file_name(Atom)),atomic_list_concat(List,'/',Atom),!,concat_paths(List,Result).
enumerate_files1(Spec,Result):- exists_file_or_dir(Spec),!,Result=Spec.
enumerate_files1(P/C,Result):- !,concat_paths(P,C,Result).
enumerate_files1(Spec,Result):- expand_file_name_safe(Spec,ResultList),member(Result,ResultList).
enumerate_files1(Spec,Result):- user:file_search_path(Spec,Result).
enumerate_files1(Spec,Result):- expand_file_search_path(Spec,Result).
enumerate_files1(Spec,Result):- absolute_file_name(Spec,Result).
enumerate_files1(Atom,Result):- atomic(Atom),once((member(Sep,['/**/','/**','**']),atomic_list_concat([B,A|R],Sep,Atom))),concat_paths([B,'**',A|R],Result).

:- export(expand_file_name_safe/2).

%= 	 	 

%% expand_file_name_safe( ?I, ?O) is semidet.
%
% Expand File Name Safely Paying Attention To Corner Cases.
%
expand_file_name_safe(I,O):-var(I),trace_or_throw(expand_file_name_safe(I,O)),!.
expand_file_name_safe(I,O):- \+ compound(I), catch(expand_file_name(I,O),_,fail),O\=[],!.
expand_file_name_safe(I,[O]):- catch(expand_file_search_path(I,O),_,fail),!.
expand_file_name_safe(I,L):- 
  findall(O,
    (absolute_file_name(I,O,[expand(true),solutions(all)]);absolute_file_name(I,O,[expand(true),solutions(all),file_type(directory)])),
    L),!.

:- export(exists_file_or_dir/1).

%= 	 	 

%% exists_file_or_dir( ?X) is semidet.
%
% Exists File Or Dir.
%
exists_file_or_dir(X):- nonvar(X),( X=(_:F)->exists_file_or_dir(F); (atomic(X),once((catch(exists_file(X),E,(fmt(E:X),fail));is_directory(X))))).
:- export(is_directory/1).

%= 	 	 

%% is_directory( ?X) is semidet.
%
% If Is A Directory.
%
is_directory(X):-exists_directory(X).

:- export(concat_paths/3).

%= 	 	 

%% concat_paths( ?ParentIn, ?Child, ?Result) is semidet.
%
% Concat Paths.
%
concat_paths(A,'',A).
concat_paths(A,'/',A).
concat_paths(ParentIn,'**',Result):-!, member(Child,['./','./*/','./*/*/','./*/*/*/','./*/*/*/*/','./*/*/*/*/*/']),concat_paths(ParentIn,Child,Result).
concat_paths(ParentIn,Child,Result):- filematch(ParentIn,Parent),
   once((is_directory(Parent) -> directory_file_path(Parent,Child,Joined) ; atom_concat(Parent,Child,Joined))),!,
   filematch(Joined,Result).

:- export(concat_paths/2).

%= 	 	 

%% concat_paths( :TermJoined, ?Result) is semidet.
%
% Concat Paths.
%
concat_paths([Joined],Result):- !,filematch(Joined,Result).
concat_paths([ParentIn,Child|MORE],Result):- concat_paths(ParentIn,Child,ResultM),concat_paths([ResultM|MORE],Result).


:- thread_local(t_l:search_first_dir/1).


%= 	 	 

%% current_dirs( ?DO) is semidet.
%
% Current Dirs.
%
current_dirs(DO):- no_repeats(DO,(current_dirs0(D),(atom_concat(DO,'/',D)->true;DO=D))).

%= 	 	 

%% current_dirs0( ?D) is semidet.
%
% Current Dirs Primary Helper.
%
current_dirs0(D):- t_l:search_first_dir(D).
current_dirs0(D):- prolog_load_context(directory,D).
current_dirs0(D):- working_directory(D,D).
current_dirs0(D):- current_stream(_,read,Y), stream_property(Y,file_name(FN)), file_directory_name(FN,D).
current_dirs0(D):- stream_property(_,file_name(FN)), file_directory_name(FN,D).

%current_dirs0(D):- expand_file_name('*/',X),member(E,X),absolute_file_name(E,D),exists_directory(D).
%current_dirs0(D):- expand_file_name('*/*/',X),member(E,X),absolute_file_name(E,D),exists_directory(D).
%current_dirs0(D):- expand_file_name('*/*/*/',X),member(E,X),absolute_file_name(E,D),exists_directory(D).
current_dirs0(D):- source_file_property(FN, modified(_)), file_directory_name(FN,D).
current_dirs0('.').

:- export(to_filename/2).
:- thread_local(t_l:default_extension/1).

%= 	 	 

%% to_filename( ?FileName, ?AFN) is semidet.
%
% Converted To Filename.
%
to_filename( FileName, AFN ) :- atomic(FileName),exists_file(FileName),!,AFN=FileName.
to_filename( FileName, AFN ) :-
 ((((t_l:default_extension( Ext ));Ext='.tlp';Ext='';Ext='.pl'), 
     current_dirs(D),
     member(TF,[false,true]),
        absolute_file_name(FileName,AFN,[solutions(all),expand(TF),access(read),relative_to(D),file_errors(fail),extensions(['',Ext,'.pl','.tlp','.clp','.P'])]),
        exists_file(AFN))),!.


:- export((add_to_search_path/2,add_to_search_path_first/2,prolog_file_dir/2,if_startup_script/1,if_startup_script/0)).

:- export(prolog_file_dir/1).

%= 	 	 

%% prolog_file_dir( ?Here) is semidet.
%
% Prolog File Dir.
%
prolog_file_dir(Here):- prolog_load_context(file, HereF),file_directory_name(HereF,Here).
prolog_file_dir(Here):- working_directory(Here,Here).
:- export(prolog_file_dir/2).

%= 	 	 

%% prolog_file_dir( ?Rel, ?ABSF) is semidet.
%
% Prolog File Dir.
%
prolog_file_dir(Rel,ABSF):-prolog_file_dir(Here),absolute_file_name(Rel,ABSF,[relative_to(Here),file_type(directory),expand(true)]),!.
prolog_file_dir(Rel,ABSF):-prolog_file_dir(Here),absolute_file_name(Rel,ABSF,[relative_to(Here),expand(true)]),!.


%% in_include_file is semidet.
%
% In Include File.
%
in_include_file:- prolog_load_context(file,F),!, \+ prolog_load_context(source,F).

%= 	 	 

%% remove_search_path( ?Alias, ?Abs) is semidet.
%
% Remove Search Path.
%
remove_search_path(Alias, Abs) :- ignore((clause(user:file_search_path(Alias, AbsW),true,Ref),same_file(Abs,AbsW),erase(Ref),fail)).

%= 	 	 

%% add_to_search_path_first( ?Alias, ?Abs) is semidet.
%
% Add Converted To Search Path First.
%
add_to_search_path_first(Alias, Abs) :- remove_search_path(Alias, Abs), asserta(user:file_search_path(Alias, Abs)).

%= 	 	 

%% add_to_search_path_last( ?Alias, ?Abs) is semidet.
%
% Add Converted To Search Path Last.
%
add_to_search_path_last(Alias, Abs) :- remove_search_path(Alias, Abs), assertz(user:file_search_path(Alias, Abs)).

%= 	 	 

%% in_search_path( ?Alias, ?Abs) is semidet.
%
% In Search Path.
%
in_search_path(Alias, Abs) :- user:file_search_path(Alias,Was),same_file(Abs,Was).



%= 	 	 

%% add_to_search_path( ?Alias, ?Abs) is semidet.
%
% Add Converted To Search Path.
%
add_to_search_path(Alias, Abs):- add_to_search_path(add_to_search_path_last, Alias, Abs).
:- meta_predicate add_to_search_path(2,?,?).

%= 	 	 

%% add_to_search_path( :PRED2How, ?Alias, ?Abs) is semidet.
%
% Add Converted To Search Path.
%
add_to_search_path(How, Alias, AbsIn) :- strip_module(AbsIn,_,Abs),!,
  ( (atom(Abs),is_absolute_file_name(Abs)) -> call(How,Alias,Abs)     
   ; (prolog_file_dir(Abs,ABSF),call(How,Alias,ABSF))).

:- add_to_search_path(logicmoo, './../').


% Was this our startup file?

%= 	 	 

%% if_startup_script is semidet.
%
% If Startup Script.
%
if_startup_script:- prolog_load_context(source, HereF),current_prolog_flag(associated_file,HereF),!.
if_startup_script:- prolog_load_context(source, HereF),file_base_name(HereF,HereFB),
   current_prolog_flag(os_argv,List),!,member(Arg,List),file_base_name(Arg,ArgFB),atom_concat(ArgFB,_,HereFB),!.

:- meta_predicate(if_startup_script(0)).

%= 	 	 

%% if_startup_script( :GoalCall) is semidet.
%
% If Startup Script.
%
if_startup_script(Call):-if_startup_script->Call;dmsg(\+ if_startup_script(Call)).

:- export(normalize_path/2).

%= 	 	 

%% normalize_path( ?Where, ?WhereF3) is semidet.
%
% Normalize Path.
%
normalize_path(Where,WhereF3):-absolute_file_name(Where,WhereF),prolog_to_os_filename(WhereF,WhereF1),prolog_to_os_filename(WhereF2,WhereF1),!,clip_dir_sep(WhereF2,WhereF3).
normalize_path(Where,WhereF2):-clip_dir_sep(Where,WhereF2).


%= 	 	 

%% clip_dir_sep( ?Where, ?WhereF2) is semidet.
%
% Clip Dir Sep.
%
clip_dir_sep('/','/'):-!.
clip_dir_sep(Where,WhereF2):-atom_concat(WhereF2,'/',Where),!.
clip_dir_sep(Where,Where):-!.



%= 	 	 

%% my_absolute_file_name( ?F, ?A) is semidet.
%
% My Absolute File Name.
%
my_absolute_file_name(F,A):-catch(expand_file_name(F,[A]),_,fail),F\=A,!.
my_absolute_file_name(F,A):-catch(absolute_file_name(F,A),_,fail),!.

% register search path hook



%= 	 	 

%% join_path_if_needed( ?A, ?B, ?C) is semidet.
%
% Join Path If Needed.
%
join_path_if_needed(A,B,C):-exists_directory(B)->B=C;directory_file_path(A,B,C).


%= 	 	 

%% locally_to_dir( ?Locally, ?Dir) is semidet.
%
% Locally Converted To Dir.
%
locally_to_dir(Locally,Dir):- clause(user:file_search_path(logicmoo,RunDir),true),join_path_if_needed(RunDir,Locally,Directory),my_absolute_file_name(Directory,Dir),exists_directory(Dir),!.
locally_to_dir(Directory,Dir):-my_absolute_file_name(Directory,Dir),exists_directory(Dir),!.



:- dynamic(local_directory_search/1).


% user:file_search_path(library,ATLIB):-getenv('PATH_INDIGOLOG',AT),atom_concat(AT,'/lib',ATLIB).
% user:file_search_path(indigolog,AT):-getenv('PATH_INDIGOLOG',AT).
% user:file_search_path(logicmoo,Dir):-  local_directory_search(Locally), locally_to_dir(Locally,Dir).



%= 	 	 

%% local_directory_search_combined( ?X) is semidet.
%
% Local Directory Search Combined.
%
local_directory_search_combined(X):-local_directory_search(X).
local_directory_search_combined(X):-local_directory_search_combined2(X).
% for now dont do the concat 3 version
local_directory_search_combined(PL):-local_directory_search_combined2(A),local_directory_search(B),join_path(A,B,PL),exists_directory_safe(PL).

%= 	 	 

%% local_directory_search_combined2( ?PL) is semidet.
%
% Local Directory Search Combined Extended Helper.
%
local_directory_search_combined2(PL):-local_directory_search(A),local_directory_search(B),join_path(A,B,PL),exists_directory_safe(PL).
:- multifile(local_directory_search/1).
:- dynamic(local_directory_search/1).
% Add the locations that the MUD source files will be picked up by the system
%local_directory_search('../..').
%local_directory_search('~logicmoo-mud/cynd/startrek'). % home vtDirection CynD world
% local_directory_search('.').
% local_directory_search('..'). 
%local_directory_search('../runtime'). 
%local_directory_search('../src_game'). % for user overrides and uploads
%local_directory_search('../src_assets').  % for non uploadables (downloadables)
%local_directory_search('../src_modules'). % for big modules
%local_directory_search('../src_webui').  % for web UI modules

%= 	 	 

%% local_directory_search( ?VALUE1) is semidet.
%
% Local Directory Search.
%
local_directory_search('../src'). % shared_library preds
local_directory_search('../src_lib').
local_directory_search('../src_mud').  % for vetted src of the MUD
%local_directory_search('../externals/XperiMental/src_incoming').  % areeba underlay





%= 	 	 

%% exists_dirf( ?X) is semidet.
%
% Exists Dirf.
%
exists_dirf(X):-atomic(X),(exists_file(X);exists_directory(X)).

%= 	 	 

%% atom_concat_safe( ?L, ?R, ?A) is semidet.
%
% Atom Concat Safely Paying Attention To Corner Cases.
%
atom_concat_safe(L,R,A):- ((atom(A),(atom(L);atom(R))) ; ((atom(L),atom(R)))), !, atom_concat(L,R,A),!.

%= 	 	 

%% exists_file_safe( ?File) is semidet.
%
% Exists File Safely Paying Attention To Corner Cases.
%
exists_file_safe(File):- ((nonvar(File),(File=(_:F)->exists_file_safe(F);(atomic(File),exists_file(File))))).

%= 	 	 

%% exists_directory_safe( ?File) is semidet.
%
% Exists Directory Safely Paying Attention To Corner Cases.
%
exists_directory_safe(File):- must(atomic(File)),exists_directory(File).
/*
concat_atom_safe(List,Sep,[Atom]):-atom(Atom),!,concat_atom(List,Sep,Atom),!.
concat_atom_safe(List,Sep,Atom):-atom(Atom),!,concat_atom(ListM,Sep,Atom),!,List = ListM.
concat_atom_safe(List,Sep,Atom):- concat_atom(List,Sep,Atom),!.
*/

%= 	 	 

%% upcase_atom_safe( ?A, ?B) is semidet.
%
% Upcase Atom Safely Paying Attention To Corner Cases.
%
upcase_atom_safe(A,B):-atom(A),upcase_atom(A,B),!.

%= 	 	 

%% time_file_safe( ?F, ?INNER_XML) is semidet.
%
% Time File Safely Paying Attention To Corner Cases.
%
time_file_safe(_:F,INNER_XML):-atom(F),!,exists_file_safe(F),time_file(F,INNER_XML).
time_file_safe(F,INNER_XML):-exists_file_safe(F),!,time_file(F,INNER_XML).



:- meta_predicate(if_file_exists(:)).

%= 	 	 

%% if_file_exists( ?M) is semidet.
%
% If File Exists.
%
if_file_exists(M:Call):- arg(1,Call,File),(filematch(File,_)-> must((filematch(File,X),exists_file(X),call(M:Call)));fmt(not_installing(M,Call))),!.




% =================================================================================
% Utils
% =================================================================================


%= 	 	 

%% global_pathname( ?B, ?A) is semidet.
%
% Global Pathname.
%
global_pathname(B,A):-absolute_file_name(B,A),!.
global_pathname(B,A):-relative_pathname(B,A).


%= 	 	 

%% relative_pathname( ?Path, ?Relative) is semidet.
%
% Relative Pathname.
%
relative_pathname(Path,Relative):-absolute_file_name(Path,[relative_to('./')],Absolute),member(Rel,['./','../','../../']),absolute_file_name(Rel,Clip),
  canonical_pathname(Absolute,AbsoluteA),
  canonical_pathname(Clip,ClipA),
  atom_concat_safe(ClipA,RelativeA,AbsoluteA),!,atom_concat_safe(Rel,RelativeA,Relative),!.
relative_pathname(Path,Relative):-canonical_pathname(Path,Relative),!.


%= 	 	 

%% canonical_pathname( ?Absolute, ?AbsoluteB) is semidet.
%
% Canonical Pathname.
%
canonical_pathname(Absolute,AbsoluteB):-prolog_to_os_filename(AbsoluteA,Absolute),expand_file_name(AbsoluteA,[AbsoluteB]),!.



% ===============================================================================================
% join_path(CurrentDir,Filename,Name)
% ===============================================================================================




%= 	 	 

%% join_path( ?CurrentDir, ?Filename, ?Name) is semidet.
%
% Join Path.
%
join_path(CurrentDir,Filename,Name):-
     atom_ensure_endswtih(CurrentDir,'/',Out),atom_ensure_endswtih('./',Right,Filename),
     atom_concat(Out,Right,Name),!.

:- multifile current_directory_search/1.
:- module_transparent current_directory_search/1.


%= 	 	 

%% atom_ensure_endswtih( ?A, ?E, ?A) is semidet.
%
% Atom Ensure Endswtih.
%
atom_ensure_endswtih(A,E,A):-atom(E),atom_concat(_Left,E,A),!.
atom_ensure_endswtih(A,E,O):-atom(A),atom(E),atom_concat(A,E,O),!.
atom_ensure_endswtih(A,E,O):-atom(A),atom(O),atom_concat(A,E,O),!.
atom_ensure_endswtih(A,O,O):-atom(A),atom(O),!.


%= 	 	 

%% os_to_prolog_filename( ?OS, ?PL) is semidet.
%
% Outputs Converted To Prolog Filename.
%
os_to_prolog_filename(OS,_PL):-sanity(atom(OS)),fail.
os_to_prolog_filename(_OS,PL):-sanity(var(PL)),fail.
os_to_prolog_filename(OS,PL):-exists_file_safe(OS),!,PL=OS.
os_to_prolog_filename(OS,PL):-exists_directory_safe(OS),!,PL=OS.
os_to_prolog_filename(OS,PL):-current_directory_search(CurrentDir),join_path(CurrentDir,OS,PL),exists_file_safe(PL),!.
os_to_prolog_filename(OS,PL):-current_directory_search(CurrentDir),join_path(CurrentDir,OS,PL),exists_directory_safe(PL),!.

os_to_prolog_filename(OS,PL):-atom(OS),atomic_list_concat([X,Y|Z],'\\',OS),atomic_list_concat([X,Y|Z],'/',OPS),!,os_to_prolog_filename(OPS,PL).
os_to_prolog_filename(OS,PL):-atom_concat_safe(BeforeSlash,'/',OS),os_to_prolog_filename(BeforeSlash,PL).
os_to_prolog_filename(OS,PL):-absolute_file_name(OS,OSP),OS \== OSP,!,os_to_prolog_filename(OSP,PL).

