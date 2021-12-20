/**
* Name: festival
* Based on the internal empty template. 
* 
*
* Author: Axel Goris and Tobias Skov
* Tags: 
*/

/*
 * TODO :
 * - Create People
 * - Make sure two places do not spawn at the same place
 * - Manage Enter and Leave
 * - Manage Interaction between People
 * - Create Specific Interaction between People
 * 
 */

model festival
// ============= INIT ============== //
global 
{
	//Places
	int nbConcert <- 0;
	int nbBar <- 1;
	//People
	int nbDrinker <- 4;
	int nbMusicLover <-0;
	int nbPartyer <- 2;
	int nbThief <- 0;
	int nbLemmeOut <- 4;
	int nbPeople <- nbDrinker +	nbMusicLover + nbPartyer + nbThief + nbLemmeOut;
	//Typical messages used for every communication by every agents
	string enterPlace <- "Can I come in ? Where ?";
	string leavePlace <- "Thanks and See ya !";
	string hereIsYourPlace <- "Here is your place : ";
	string gimmeSomeoneToInvite <- "I want to meet new people! Bring me someone cool !";
	string youAreInvited <- " is inviting you ! Go thank him !";
	string sendMessageAboutPlace <- "Send info about place";
	string recieveMessageAboutPlace <- "recieve info about place";
	string whoIsInHere <- "Who is in here";
	string presentGuestMessage <- "the guests here are";
	string whatIsTheMusicGenre <- "what is the music genre";
	string musicInfo <- "music info";
	
	string meetingPlaceBar <- "Bar";
	string meetingPlaceConcert  <- "Concert";

	
	
	//A list of every places agents can meet
	list<MeetingPlace> meetingPlace <- [];
	
	float globalHappiness <- 0.0;
	
	reflex updateGlobalHappiness when: cycle mod 5 = 4 {
		globalHappiness <- 0.0;
		
		loop i over: list(Drinker){
			globalHappiness <- globalHappiness + i.happiness;
		}
		loop i over: list(MusicLover){
			globalHappiness <- globalHappiness + i.happiness;
		}
		loop i over: list(Partyer){
			globalHappiness <- globalHappiness + i.happiness;
		}
		loop i over: list(Thief){
			globalHappiness <- globalHappiness + i.happiness;
		}
		loop i over: list(LemmeOut){
			globalHappiness <- globalHappiness + i.happiness;
		}
		
		// calculate average happiness
		globalHappiness <- globalHappiness /nbPeople;
	}
	
	init
	{
		//Creation and list of every meeting place possible
		create Bar number: nbBar;
		create Concert number: nbConcert;
		meetingPlace <- list(Bar) + list(Concert);
		
		//Creation of every person
		create Drinker number: nbDrinker;
		create Partyer number: nbPartyer;
		create MusicLover number: nbMusicLover;
		create Thief number: nbThief;
		create LemmeOut number: nbLemmeOut;
	}

}

//Parent of every places we're gonna create
//Handle people going in and out
species MeetingPlace skills:[fipa]{
	// ========== ATTRIBUTES ========== //
	image_file icon <- nil;
	//The last float is the transparency of the place
	rgb color <- rgb(0, 0, 0, 1);
	//The area around the place : depends on what type of places that is
	float distanceOfInfluence <- 0.0;
	geometry areaOfInfluence <- circle(distanceOfInfluence);
	//a list of guests
	list<Person> guests <- [];
	string meetingPlaceType <- "";
	
	
	reflex handleRequests when: !empty(requests) {
		
		loop r over: requests {
			list<unknown> c <- r.contents;
			
			if(c[0] = recieveMessageAboutPlace) {
				point placeForTheGuest <- any_location_in(areaOfInfluence);
				do inform message: r contents: [sendMessageAboutPlace, placeForTheGuest];
			}
			else if(c[0] = whoIsInHere) {
				do inform message: r contents: [presentGuestMessage, guests];
			}
		}
	}
	
	// === MANAGE PEOPLE IN AND OUT === //
	///When someone walks in, we add him to the list of guest and we give him any place inside the area
	reflex someoneIn when: !empty(subscribes) {
		loop s over: subscribes{
			add s.sender to: guests;
			point placeForTheGuest <- any_location_in(areaOfInfluence);
			do inform with:(message: s, contents:[hereIsYourPlace, placeForTheGuest]);
		}
	}
	
	///When someone walks out, we remove him from the list of guests
	reflex someoneOut when: !empty(informs) {
		loop i over: informs{
			remove i.sender from: guests;
		}
	}
	
	///Manage the guy who invited and the guy who's gonna be invited
	reflex someoneShouldBeInvited when: !empty(cfps) {
		loop invitation over: cfps {
			if(length(guests) > 1){
				write length(guests);
				list<unknown>c <- invitation.contents;
				Person invitedGuest <- randomGuest(invitation.sender);
				do start_conversation to: [invitedGuest] performative: 'propose' contents: [youAreInvited, invitation.sender];
			}
		}
	}
	
	/// Allows to pick a random guest
	Person randomGuest(Person invitor){	
		Person random <- any(guests);
		//If we picked the guy who invited, then we pick another one, so on and so forth
		loop while: invitor = random{
			random <- any(guests);
		}
		return random;
	}
	
	// ============== GRAPHICAL ==========
	aspect default {
		draw areaOfInfluence color: color;
		draw icon size: 4.5;		
	}
}

species Concert parent: MeetingPlace{
	// ========== ATTRIBUTES ========== //
	image_file icon <- image_file("../includes/stage.png");
	float distanceOfInfluence <- 10.0;
	rgb color <- rgb(255, 0, 0, 0.5);
	string meetingPlaceType <- meetingPlaceConcert;
	
	float ligthing_value <- 0.0;
	float rock_value <- 0.0;
	float sound_value <- 0.0;
	float pop_value <- 0.0;
	
	reflex startConcert when:time mod 40=5 {
		ligthing_value <- rnd(float(1));
		rock_value <- rnd(float(1));
		sound_value <- rnd(float(1));
		pop_value <- rnd(float(1));
		write 'The time is ' + time + ' : ' + name + '  The next concert has started';
	}
	
	reflex SendInformation when: !empty(queries) {
		
		loop i over: queries {
			list<unknown> c <- i.contents;
			
			if(c[0] = whatIsTheMusicGenre) {
				do query message: i contents: [musicInfo, [ligthing_value, rock_value, sound_value, pop_value]];
			}
		}
	}
}

species Bar parent: MeetingPlace{
	// ========== ATTRIBUTES ========== //
	image_file icon <- image_file("../includes/pub.png");
	float distanceOfInfluence <- 5.0;
	rgb color <- rgb(0, 0, 255, 0.5);
	string meetingPlaceType <- meetingPlaceBar;
	
	
}


//Parent of every type of people we're gonna create
//Handle movement of people and basic interaction (nothing specialized here) / common attributes
species Person skills:[moving, fipa]{
	// ========== ATTRIBUTES ========== //
	image_file icon <- nil;
	rgb color <- rgb(0, 0, 0);
	
	//When going to the meeting place
	float chanceToDecideOnAPlaceToGo <- rnd(0.1);
	MeetingPlace targetPlace <- nil;
	point targetPoint <- nil;
	float distanceToEnter <- 100.0;
	bool inPlace <- false;
	
	//When inside the meeting place
	int minimumTimeInsidePlace <- rnd(10, 100);
	int maxTimeInsidePlace <- rnd(minimumTimeInsidePlace, 3*minimumTimeInsidePlace);
	int timeInside <- 0;
	float chanceToLeavePlace <- 0.0;
	
	
	//When leaving the meeting place
	bool leaving <- false;
	
	//Some people might want to invite multiple people because they feel very generous or very rich !
	int nbInvite <- 0;
	int nbInviteMax <- rnd(1,3);
	//Because sometimes you're in the mood, sometimes, you're not. But remember. 
	//John is always in the mood. Be in the mood. Be like John.
	float wantToInviteSomeone <- rnd(0.0, 1.0) update: rnd(0.0, 1.0);
	float noisyLevel <- rnd(0,0.3);
	
	// for the species interactions
	string personType <- "";
	float happiness <- 0.0;
	
	// for the lemmeout
	float Grumpy <- 0.0;
	float Drunk <- 0.0;
	float Shy <- 0.0;
	
	
	
	
	// ==================== MOVE ==================== //
	///When someone is wandering around and has no goal, he can decide on a place to go, taking a random place
	reflex decideOnAPlaceToGo when: targetPoint = nil and rnd(1.0) < chanceToDecideOnAPlaceToGo {
		targetPlace <- any(meetingPlace);
		targetPoint <- targetPlace.location;
		//This is to make it enter the place once he's inside the area of influence
		distanceToEnter <- targetPlace.distanceOfInfluence;
	}
	
	reflex wanderAround when : targetPoint = nil and !inPlace{
		do wander;
	}
	
	//Careful, we're looking for a specific point because even inside of a place, the agent can still move to a different place if he needs to!
	reflex moveToTarget when: targetPoint != nil{
		do goto target: targetPoint;
	}
	
	/// Once close enough to a place, he'll ask for a place and tell the bartender / dj that he's here because John is a safe guy. Be safe. Be like John.
	reflex enterPlace when: targetPlace != nil and self.location distance_to targetPoint < distanceToEnter and !inPlace {
		do start_conversation to: [targetPlace] performative: 'subscribe' contents: [enterPlace];
		write self.name + enterPlace + targetPlace.name;
		inPlace <- true;
	}
	
	/// Once he gets an answer from the place, he can go to the specific place he's supposed to stay into
	reflex placeToStay when: !empty(informs){
		loop i over: informs{
			list<unknown> info <- i.contents;
			if(info[0] = hereIsYourPlace){
				targetPoint <- info[1];
			}
		}
	}
	
	/// time flies by and this increases his chances of leaving the place
	reflex insidePlace when: inPlace{
		timeInside <- timeInside + 1 ;
		//Just a way to make sure he won't stay for too long
		chanceToLeavePlace <- timeInside / maxTimeInsidePlace;
	}
	
	// When he gets past a certain point, he'll start thinking about leaving and at one point in time, he will
	reflex leavePlace when: inPlace and timeInside > minimumTimeInsidePlace and rnd(1.0) < chanceToLeavePlace {
		write "Leaving after " + timeInside;
		//He informs the bartender/else that he's leaving ! Because John is polite. Be polite. Be like John.
		do start_conversation to: [targetPlace] performative: 'inform' contents: [leavePlace];
		//We're looking for a new place to go and we don't want every agent to go to the same place so we're going to pick a random point outside the area of influence
		//If it's far away enough, great, otherwise, we use this point as a direction and make the distance in this direction 1.3 times greater than the area of influence*
		// In order to pick a different point that can be anywere
		point newPoint <- {rnd(-1.0, 1.0), rnd(-1.0, 1.0)};
		//Make it into a direction
		newPoint <- newPoint / sqrt(newPoint.x*newPoint.x + newPoint.y * newPoint.y);
		write newPoint;
		targetPoint <- targetPlace.location + newPoint*2*targetPlace.distanceOfInfluence;
		targetPlace <- nil;
		inPlace <- false;
		leaving <- true;
		nbInvite <- 0;
		timeInside <- 0;
	}
	
	//This is to make sure that he goes out and once he's out, he starts to wander around and everything
	reflex goOutside when: leaving and self.location distance_to targetPoint < 5.0 {
		targetPoint <- nil;
		leaving <- false;
	}
	
	/// This is a parent action to accept  an invitation to something
	reflex acceptInvitationToWhatever when: !(empty(proposes)){
		loop p over: proposes{
			list<unknown> invitor <- p.contents;
			Person ppl <- invitor[1];
			do accept(ppl.location);
		}
	}
	
	
	
	action leavePlaceAction {
		//He informs the bartender/else that he's leaving ! Because John is polite. Be polite. Be like John.
		do start_conversation to: [targetPlace] performative: 'inform' contents: [leavePlace];
		//We're looking for a new place to go and we don't want every agent to go to the same place so we're going to pick a random point outside the area of influence
		//If it's far away enough, great, otherwise, we use this point as a direction and make the distance in this direction 1.3 times greater than the area of influence*
		// In order to pick a different point that can be anywere
		point newPoint <- {rnd(-1.0, 1.0), rnd(-1.0, 1.0)};
		//Make it into a direction
		newPoint <- newPoint / sqrt(newPoint.x*newPoint.x + newPoint.y * newPoint.y);
		write newPoint;
		targetPoint <- targetPlace.location + newPoint*2*targetPlace.distanceOfInfluence;
		targetPlace <- nil;
		inPlace <- false;
		leaving <- true;
		nbInvite <- 0;
		timeInside <- 0;
	}
	
	///This method must be overriden depending on what is going to happen ! :D
	action accept(point theGuyWhoInvited){
		write "Sure, it'll be my pleasure.";
		targetPoint <- theGuyWhoInvited + {rnd(-1,1) * rnd(0.5,1.0), rnd(-1,1) * rnd(0.5,1.0)};
	}
	
	///This a general reflex to invite someone when your inside
	reflex inviteSomeoneToWhatever when: inPlace and nbInvite < nbInviteMax and wantToInviteSomeone > 0.8 {
		nbInvite <- nbInvite + 1;
		do start_conversation to: [targetPlace] performative: 'cfp' contents:[gimmeSomeoneToInvite];
	}
	// ============== GRAPHICAL ==========
	aspect default {		
		draw icon size: 2.0;		
	}
}

species Drinker parent:Person{
	image_file icon <- image_file("../includes/drunk.png");
	
	string personType <- "Drinker";
	
	float generous <- rnd(0.4, 1.0);
	float NoiseThreshold<- 0.5;
	float drunk <- rnd(0,0.2);
	float noisyLevel <- noisyLevel + drunk;
	
	reflex askForGuests when: inPlace {
		
		do start_conversation to: [targetPlace] performative: 'request'
				contents: [whoIsInHere];

	}
	
	reflex reactOnGuests when: inPlace and !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = presentGuestMessage) {
				do TooNoisyInTheBar guests: c[1];
			}
		}
	}
	
	action TooNoisyInTheBar(list<Person> guests){ // the drinker will leave the bar based on how noisy it is
		if length(guests) >1 {
			float Noisy <- 0.0;
			
			// calculate the total noise in the place
			loop i over: guests {
				Noisy <- Noisy + i.noisyLevel;
				
			}
			
			Noisy <- Noisy / length(guests);
			
			// how drunk the person is affects their noise threshold
			if ((NoiseThreshold+drunk) < Noisy){
				write self.name + "It is way too noise and I'm leaving from " + targetPlace.name ;
				do leavePlaceAction;
			}
		
		}
	}
}

species MusicLover parent:Person{
	image_file icon <- image_file("../includes/music.png");
	float deaf <- rnd(0, 0.5);
	string personType <- "MusicLover";
	
	float ligthing_preference <- rnd(float(1));
	float rock_preference <- rnd(float(1));
	float sound_preference <- rnd(float(1));
	float pop_preference <- rnd(float(1));
	float musicScore <- 0.0;
	
	
	reflex askForMusic when: inPlace  and targetPlace.meetingPlaceType = meetingPlaceConcert{
		
		do start_conversation to: [targetPlace] performative: 'query'
				contents: [whatIsTheMusicGenre];

	}
	
	reflex reactOnMusic when: inPlace and !empty(query) {
		
		//loop i over: query {
		//	list<unknown> c <- i.contents;
		//	
		//	if(c[0] = musicInfo) {
		//		// should I stay or should i go
		//		message values <- c[1];
		//		float ligthing_value <- list(values.contents)[0];
		//		float rock_value <- list(values.contents)[1];
		//		float sound_value <- list(values.contents)[2];
		//		float pop_value <- list(values.contents)[3];
		//		
		//		musicScore <- 	(ligthing_preference * ligthing_value + rock_preference *rock_value + sound_preference * sound_value + pop_preference * pop_value);
		//		write "musicScore " + musicScore;
		//	}
		//}
	}
}

species Partyer parent:Person{
	image_file icon <- image_file("../includes/party.png");
	float noisyLevel <- rnd(0.5,1.0);
	float deaf <- rnd(0.3, 1.0);
	string personType <- "Partyer";

}

species Thief parent:Person{
	image_file icon <- image_file("../includes/thief.png");
	string personType <- "Theif";
}

species LemmeOut parent:Person{
	image_file icon <- image_file("../includes/tired.png");
	float Grumpy <- rnd(0.3, 1.0);
	float Drunk <- rnd(0.3, 1.0);
	float Shy <- rnd(0.3, 0.8);
	float happiness <- happiness;
	bool Talking <- false;
	
	string personType <- "LemmeOut";
	
	reflex askForGuests when: inPlace {
		
		do start_conversation to: [targetPlace] performative: 'request'
				contents: [whoIsInHere];

	}
	
	reflex reactOnGuests when: inPlace and !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = presentGuestMessage) {
				do FindSomebodyWhoDoesNotWantToBeHere guests: c[1];
			}
		}
	}
	
	action FindSomebodyWhoDoesNotWantToBeHere(list<Person> guests){
		if length(guests) > 1 {		
			// calculate the total noise in the place
			float personProbTalking <- (Drunk + Grumpy) - Shy;
			loop i over: guests {
				if i.personType = "LemmeOut"{
					// chekc if they are too shy to start at conversation
					if ((personProbTalking + ((i.Drunk+i.Grumpy) - i.Shy)) > 0){
						write name + "Do you also just hate being here " + i.name + " ?" + "yes it is an awefull festival";
						Talking <- true;
						//the more grumpy the people are the happineer they are talking to each other
						happiness <- happiness + (Grumpy + i.Grumpy)/2;
					}
				}
				
			}
			Talking <- false;
		}
	}
	
	
	// decay happiness if we are not talking with another grumpy person
	reflex decayHappiness when: cycle mod 40 = 4 and !Talking {
		
		happiness <- happiness - (happiness *0.01);
	}	
}

// ============== EXPERIMENT ============ //

experiment MyExperiment type:gui {
	output {
		display myDisplay {
			//Places
			species Concert;
			species Bar;
			//People
			species Drinker;
			species MusicLover;
			species Partyer;
			species Thief;
			species LemmeOut;
		}
		display HappinessChart {
			chart 'Global Happiness' type: series {
				data 'Global Happiness' value: globalHappiness color: #blue;
			}
		}
	}
}
