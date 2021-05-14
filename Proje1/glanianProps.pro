:- ['load.pro'].


getGenderByName(Name,Gender):-
    glanian(Name,Gender,_).

getFeaturesByName(Name,Features):-
    glanian(Name,_,Features).

getExpectedFeaturesByName(Name,Features):-
    expects(Name , _ , Features).

getWeightsByName(Name,Weights):-
    weight(Name,Weights).


calculateDistanceOfFeatures([], [],PrevResult,Result):-
    sqrt(PrevResult,Result).

calculateDistanceOfFeatures([H1|T1], [H2|T2],PrevResult, Result):-
    % If equal to -1, skip the current `H`s.
    ((H1 = -1),calculateDistanceOfFeatures(T1,T2,PrevResult,Result));
    % Else, find the difference and its square
    (Diff is H1 - H2,
    TempResult is PrevResult + (Diff * Diff),
    calculateDistanceOfFeatures(T1,T2,TempResult,Result)).

calculateWeightDistanceOfFeatures([], [],_,PrevResult,Result):-
    sqrt(PrevResult,Result).

calculateWeightDistanceOfFeatures([H1|T1], [H2|T2],[W1|W2],PrevResult,Result):-
    % If equal to -1, skip the current `H`s.
    (H1 =:= -1,calculateWeightDistanceOfFeatures(T1,T2,W2,PrevResult,Result);
    H1 \= -1,(Diff is H1 - H2,TempResult is PrevResult + ((Diff * Diff) * W1),calculateWeightDistanceOfFeatures(T1,T2,W2,TempResult,Result))).
    
pairListToLists([],[],[]).

pairListToLists([Head|Tail],[HTar|TTar],[HDis|TDis]):-
    (Name,Dif) = Head,
    HTar = Name,
    HDis = Dif,
    pairListToLists(Tail,TTar,TDis).


pair4ListToLists([],[],[],[],[]).

pair4ListToLists([Head|Tail],[HTar|TTar],[HDis|TDis],[HDis1|TDis1],[HDis2|TDis2]):-
    (Weight,Activity,City,Target) = Head,
    HTar = City,
    HDis = Weight,
    HDis1 = Target,
    HDis2 = Activity,
    
    pair4ListToLists(Tail,TTar,TDis,TDis1,TDis2).


getActivitiesByCities(CityList,ActivityList):-
    findall(ActNom,(member(C,CityList),city(C,_,AcList),member(ActNom,AcList)),ActivityList).

checkLimits([],_,Result):-
    Result = true.

checkLimits([HLimits|TLimits],[HTargetNomFeatures|TTargetNomFeatures],Result):-
    compareLimit(HLimits,HTargetNomFeatures,IsValid),
    (IsValid,checkLimits(TLimits,TTargetNomFeatures,Result));
    Result = false.

compareLimit([],_,X):-
    X = true.
compareLimit(Range,Value,Result):-
    [H,T] = Range,
    ((H =< Value),(T >= Value),Result = true);
    Result = false.
getLast(X,[]):-
    X = [].
getLast(X,[X]).
getLast(X,[_|L]) :- getLast(X,L).