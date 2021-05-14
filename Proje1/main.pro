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

weighted_glanian_distance(Name1,Name2,Distance):-
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



% subtract(LikedActivities,DislikedActivities,DiffActs),
% 3.8 find_my_best_target(Name, Distances, Activities, Cities, Targets) 20 points
find_my_best_target(Name, Distances, Activities, Cities, Targets):-
    find_possible_targets(Name, _, TargetList),
    expects(Name,NameExpectedGenders,_),
    find_possible_cities(Name,PossibleCities),
    getActivitiesByCities(PossibleCities,PossibleActs),
    likes(Name,LikedActivities,_),
    dislikes(Name,DislikedActivities,DislikedCities,DislikeLimits),
    findall((Weigth,ActivityNom,CityName,TargetNom),(       
        
        member(TargetNom,TargetList), 
        \+old_relation([Name,TargetNom]), % Name and Target do not have an old relation
        
        glanian(TargetNom,TargetNomGender,TargetNomFeatures), % Get Target's gender
        member(TargetNomGender,NameExpectedGenders), % Check if Name likes Target's gender
        
        checkLimits(DislikeLimits,TargetNomFeatures,Re),
        Re,
        
        likes(TargetNom,TargetNomLikedActivites,_), % Get Target's liked activities
        intersection(DislikedActivities,TargetNomLikedActivites,Intersected), % Get the intersection of opposites
        length(Intersected,NumberOfConflicts), % Get the length of opposites
        NumberOfConflicts < 3, % Check the length of opposites
        
        weighted_glanian_distance(Name,TargetNom,Weigth),
        
        merge_possible_cities(Name,TargetNom,CityListNom),
        getActivitiesByCities(CityListNom,MergedActs),
        intersection(PossibleActs,MergedActs,AvailableActivities),
        list_to_set(AvailableActivities,AvailableActivitiesSet),

        member(ActivityNom,AvailableActivitiesSet),
        \+member(ActivityNom,DislikedActivities),
    
        findall(
            CityName,
            (
                city(CityName,_,AcList),
                member(ActiNom,LikedActivities),
                member(ActiNom,AcList)
            ),
            ActivityCIties
        ),
        union(PossibleCities,ActivityCIties,AvailableCities),
        list_to_set(AvailableCities,AvailableCitiesSet),
        member(CityName,AvailableCitiesSet),
        member(CityName,CityListNom),
        \+member(CityName,DislikedCities),
        
        city(CityName,_,Ac2List),
        member(ActivityNom,Ac2List)
        ),
    AllTogether),
    msort(AllTogether,AllTogether1),
    pair4ListToLists(AllTogether1,Cities,Distances,Targets,Activities).



find_my_best_match(Name, Distances, Activities, Cities, Targets):-
    find_possible_targets(Name, _, TargetList),
    glanian(Name,NameGender,NameFeatures),
    expects(Name,NameExpectedGenders,_),
    find_possible_cities(Name,PossibleCities),
    getActivitiesByCities(PossibleCities,PossibleActs),
    likes(Name,LikedActivities,_),
    dislikes(Name,DislikedActivities,DislikedCities,DislikeLimits),
    findall((Weigth,ActivityNom,CityName,TargetNom),(       
        
        member(TargetNom,TargetList), 
        \+old_relation([Name,TargetNom]), % Name and Target do not have an old relation
        
        % 3.9.8
        expects(TargetNom,TargetNomExpectedGenders,_),
        member(NameGender,TargetNomExpectedGenders),
        
        glanian(TargetNom,TargetNomGender,TargetNomFeatures), % Get Target's gender
        member(TargetNomGender,NameExpectedGenders), % Check if Name likes Target's gender
        
        likes(TargetNom,TargetLikedActivities,_),
        dislikes(TargetNom,TargetDislikedActivities,_,TargetDislikeLimits),

        checkLimits(DislikeLimits,TargetNomFeatures,Re),
        Re,
        % 3.9.10
        checkLimits(TargetDislikeLimits,NameFeatures,Re2),
        Re2,

        
        
        intersection(DislikedActivities,TargetLikedActivities,Intersected), % Get the intersection of opposites
        length(Intersected,NumberOfConflicts), % Get the length of opposites
        NumberOfConflicts < 3, % Check the length of opposites
        % 3.9.12
        intersection(TargetDislikedActivities,LikedActivities,Intersected2), % Get the intersection of opposites
        length(Intersected2,NumberOfConflicts2), % Get the length of opposites
        NumberOfConflicts2 < 3, % Check the length of opposites
        
        weighted_glanian_distance(Name,TargetNom,Weigth1),
        weighted_glanian_distance(TargetNom,Name,Weigth2),
        Weigth is (Weigth1 + Weigth2) / 2,
        
        merge_possible_cities(Name,TargetNom,CityListNom),
        getActivitiesByCities(CityListNom,MergedActs),

        find_possible_cities(TargetNom,TargetPossibleCities),
        getActivitiesByCities(TargetPossibleCities,TargetPossibleActs),

        intersection(PossibleActs,MergedActs,AvailableActivities),
        list_to_set(AvailableActivities,AvailableActivitiesSet),

        member(ActivityNom,AvailableActivitiesSet),
        \+member(ActivityNom,DislikedActivities),
        member(ActivityNom,TargetPossibleActs),
        

        findall(
            CityName,
            (
                city(CityName,_,AcList),
                member(ActiNom,LikedActivities),
                member(ActiNom,AcList)
            ),
            ActivityCIties
        ),
        union(PossibleCities,ActivityCIties,AvailableCities),
        list_to_set(AvailableCities,AvailableCitiesSet),

        findall(
            CityName,
            (
                city(CityName,_,AcList),
                member(ActiNom,TargetLikedActivities),
                member(ActiNom,AcList)
            ),
            TargetActivityCIties
        ),
        union(TargetPossibleCities,TargetActivityCIties,TargetAvailableCities),
        list_to_set(TargetAvailableCities,TargetAvailableCitiesSet),

        member(CityName,AvailableCitiesSet),
        member(CityName,TargetAvailableCitiesSet),
        member(CityName,CityListNom),
        \+member(CityName,DislikedCities),
        
        city(CityName,_,Ac2List),
        member(ActivityNom,Ac2List)
        ),
    AllTogether),
    msort(AllTogether,AllTogether1),
    pair4ListToLists(AllTogether1,Cities,Distances,Targets,Activities).



bonus(BestTen):-
    Names = [josizar,anthgall,jaylren,yagrot,nysow,gold_aid,thinnest,engakib,rhenali,fabsold,steno],
    findall(Couple,
    (
        glanian(Name,_,_), % Select a glanian
        member(Name,Names),
        write(Name),
        write('\n'),
        find_my_best_match(Name, Distances, _, _, Targets),
        getLast(BestTarget,Targets),
        getLast(BestDistance,Distances),
        Couple = (Name,BestTarget,BestDistance),
        print(Couple)
        
    ),BestTen).

bonus2([Current|TailNames],[H|All]):-
        Name = Current,
        glanian(Name,_,_), % Select a glanian
        member(Name,Names),
        find_my_best_match(Name, Distances, _, _, Targets),
        getLast(BestTarget,Targets),
        getLast(BestDistance,Distances),
        H = (Name,BestTarget,BestDistance),
        bonus2(TailNames,All).
bonus2([],All).
