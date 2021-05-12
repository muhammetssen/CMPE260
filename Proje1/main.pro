% include the knowledge base
:- ['load.pro','glanianProps.pro'].

getDifferencesByNames(_,[],TempList,DifferenceList):-
    DifferenceList = TempList.


getDifferencesByNames(BaseName,[Name|Tail],TempList,DifferenceList):-
    glanian_distance(BaseName,Name,Dif),
    append(TempList,[(Name,Dif)],T),
    getDifferencesByNames(BaseName,Tail,T,DifferenceList).

getWeightDifferencesByNames(_,[],TempList,DifferenceList):-
    DifferenceList = TempList.


getWeightDifferencesByNames(BaseName,[Name|Tail],TempList,DifferenceList):-
    weighted_glanian_distance(BaseName,Name,Dif),
    append(TempList,[(Name,Dif)],T),
    getWeightDifferencesByNames(BaseName,Tail,T,DifferenceList).



glanian_distance(Name1,Name2,Distance):-
    getExpectedFeaturesByName(Name1, Features1), % Get Expected Features of Name 1
    getFeaturesByName(Name2, Features2), % Get Features of Name 2
    calculateDistanceOfFeatures(Features1,Features2,0,Distance).

weighted_glanian_distance(Name1, Name2, Distance):-
    getExpectedFeaturesByName(Name1, Features1), % Get Expected Features of Name 1
    getFeaturesByName(Name2, Features2), % Get Features of Name 2
    getWeightsByName(Name1,Weights),
    calculateWeightDistanceOfFeatures(Features1,Features2,Weights,0,Distance).

find_possible_cities(Name, CityList):-
    city(CurrentCity,Habitants,_),member(Name,Habitants),    
    likes(Name,_,LikedCities),
    CityList = [CurrentCity|LikedCities].   

merge_possible_cities(Name1, Name2, MergedCities):-
    find_possible_cities(Name1,Cities1),
    find_possible_cities(Name2,Cities2),
    union(Cities1, Cities2, MergedCities).
    
find_mutual_activities(Name1, Name2, MutualActivities):-
    likes(Name1,Activities1,_),
    likes(Name2,Activities2,_),
    intersection(Activities1,Activities2, MutualActivities).
    

find_possible_targets(Name, Distances, TargetList):-
    expects(Name, ExpectedGenders,_),
    findall(NomName,(glanian(NomName,NomGender,_),member(NomGender,ExpectedGenders)),FoundNames),
    getDifferencesByNames(Name,FoundNames,[],Pairs),
    sort(2,@=<,Pairs , Sorted),
    pairListToLists(Sorted,TargetList,Distances).

find_weighted_targets(Name, Distances, TargetList):-
    expects(Name, ExpectedGenders,_),
    findall(NomName,(glanian(NomName,NomGender,_),member(NomGender,ExpectedGenders)),FoundNames),
    getWeightDifferencesByNames(Name,FoundNames,[],Pairs),
    sort(2,@=<,Pairs , Sorted),
    pairListToLists(Sorted,TargetList,Distances).



% 3.8 find_my_best_target(Name, Distances, Activities, Cities, Targets) 20 points
find_my_best_target(Name, Distances, Activities, Cities, Targets):-
    find_possible_cities(Name,)
% 3.9 find_my_best_match(Name, Distances, Activities, Cities, Targets) 25 points
    