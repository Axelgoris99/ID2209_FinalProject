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
 * - Make sure two places do not spawn at the same place
 * DONE :
 * - Manage Enter and Leave
 * - Manage Interaction between People
 * - Create Specific Interaction between People
 * - Create People
 */

model festival
// ============= INIT ============== //
global 
{
	//Places
	int nbConcert <- 1;
	int nbBar <- 1;
	//People
	int nbDrinker <- 12;
	int nbMusicLover <-12;
	int nbPartyer <- 12;
	int nbThief <- 8;
	int nbLemmeOut <- 10;
	int nbPeople <- nbDrinker +	nbMusicLover + nbPartyer + nbThief + nbLemmeOut;
	//Typical messages used for every communication by every agents
	string enterPlace <- "Can I come in ? Where ?";
	string leavePlace <- "Thanks and See ya !";
	string hereIsYourPlace <- "Here is your place : ";
	string gimmeSomeoneToInvite <- "I want to meet new people! Bring me someone cool !";
	string youAreInvited <- " is inviting you ! Go thank him !";
	string whoIsInHere <- "Who is in here";
	string presentGuestMessage <- "the guests here are";
	string whatIsTheMusicGenre <- "what is the music genre";
	string musicInfo <- "music info";
	
	string meetingPlaceBar <- "Bar";
	string meetingPlaceConcert  <- "Concert";

	
	//A list of every places agents can meet
	list<MeetingPlace> meetingPlace <- [];
	
	float globalHappiness <- 0.0;
	float globalHappinessStolen <- 0.0;
	
	reflex updateGlobalHappiness when: cycle mod 5 = 4 {
		globalHappiness <- 0.0;
		globalHappinessStolen <- 0.0;
		
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
			globalHappinessStolen <- globalHappinessStolen+ i.happinessStolen;
		}
		loop i over: list(LemmeOut){
			globalHappiness <- globalHappiness + i.happiness;
		}
		
		// calculate average happiness
		globalHappiness <- globalHappiness /nbPeople;
		if nbThief > 0{
			globalHappinessStolen <- globalHappinessStolen/nbThief;
		}
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
	
	
	reflex SendInformationBasedOnRequests when: !empty(requests) {
		
		loop i over: requests {
			list<unknown> c <- i.contents;
			if(c[0] = whoIsInHere) {
				do inform message: i contents: [presentGuestMessage, guests];
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
	
	float chill_value <- 0.0;
	float rock_value <- 0.0;
	float sound_value <- 0.0;
	float pop_value <- 0.0;
	list<float> musicValue <- [chill_value, rock_value, sound_value, pop_value];

	
	reflex startConcert when:time mod 40=5 { //start at concert every 40 seconds with random values
		chill_value <- rnd(float(1));
		rock_value <- rnd(float(1));
		sound_value <- rnd(float(1));
		pop_value <- rnd(float(1));
		musicValue <- [chill_value, rock_value, sound_value, pop_value];
		write 'The time is ' + time + ' : ' + name + '  The next concert has started';
	}
	
	reflex InformAboutTheConcert when: !empty(subscribes) {
		loop s over: subscribes{
			add s.sender to: guests;
			do inform with:(message: s, contents:[musicInfo,musicValue]);
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
	
	bool askForOtherGuests <- false;
	
	//Some people might want to invite multiple people because they feel very generous or very rich !
	int nbInvite <- 0;
	int nbInviteMax <- rnd(1,3);
	//Because sometimes you're in the mood, sometimes, you're not. But remember. 
	//John is always in the mood. Be in the mood. Be like John.
	float wantToInviteSomeone <- rnd(0.0, 1.0) update: rnd(0.0, 1.0);
	
	
	// for the species interactions
	string personType <- "";
	float happiness <- rnd(1.0);
	
	// Traits used by the species to check each others scores
	//float Grumpy <- 0.0;
	//float Drunk <- 0.0;
	//float Shy <- 0.0;
	//float chill <- 0.0;
	//float deaf <- 0.0;
	float noisyLevel <- rnd(0,0.3);
	
	
	
	
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
		askForOtherGuests <- false;
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
	
	reflex askForGuests when: inPlace and !askForOtherGuests {
		do start_conversation to: [targetPlace] performative: 'request'
				contents: [whoIsInHere];
		askForOtherGuests <- true;
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
	
	//the drinkers personality traits
	float generous <- rnd(0.4, 1.0);
	float NoiseThreshold<- 0.5;
	float drunk <- rnd(0,0.2);
	float noisyLevel <- noisyLevel + drunk;
	
	
	reflex reactOnGuests when: inPlace and !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = presentGuestMessage) {
					list<Person> guests <- c[1];
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
							happiness <- happiness - (happiness*0.5) ;
							do leavePlaceAction;
						}
						else{
							write self.name + "The bar is nice and quite " + targetPlace.name ;
							happiness <- happiness + 0.1;
						}
					}
			}
		}
	}
}

species MusicLover parent:Person{
	image_file icon <- image_file("../includes/music.png");
	
	string personType <- "MusicLover";
	
	//The music preference of the Music Lover
	float chill_preference <- rnd(float(1));
	float rock_preference <- rnd(float(1));
	float sound_preference <- rnd(float(1));
	float pop_preference <- rnd(float(1));
	float musicScore <- 0.0;
	
	// The personality score of the Music Lover
	float deaf <- rnd(0.2, 0.8);
	float chill <- rnd(0.2,0.8);
	float musicPreference <- rnd(0.2,0.6);

	
	
	reflex AskForMusicInfo when:!empty(informs){ // here we check what music is being played at the concert
		loop i over: informs{
			
			list<unknown> musicValue <- i.contents;
			list<float> musicValueList <- musicValue[1];
			
			if (musicValue[0] != musicInfo){
				do leavePlaceAction;
			if(musicValue[0] = musicInfo){
		
				float chill_value <- musicValueList[0];
				float rock_value <- musicValueList[1];
				float sound_value <- musicValueList[2];
				float pop_value <-musicValueList[3];
				
				// calculate the total music score
				// the more deaf they are the less they care about the music
				rock_value <- rock_value * (1+deaf);
				sound_value <- sound_value * (1+deaf);
				pop_value <- pop_value * (1+deaf);
				// how chill the person is affect the chill value of the music
				chill_value <- chill_value *(1+chill);
				
				musicScore <- (chill_preference * chill_value + rock_preference *rock_value + sound_preference * sound_value + pop_preference * pop_value) ;
				if musicScore < musicPreference {
					
					// they leave the concert
					write self.name + "The music is not good enough here and I'm leaving from " + targetPlace.name ;
					happiness <- happiness - (happiness*0.5) ;
					do leavePlaceAction;	
				}
				else{
					happiness <- happiness + (musicScore);

					write self.name + " The music is amazing here " + targetPlace.name ;
					
					// Find somebody to talk about music with
					loop i over: informs {
						list<unknown> c <- i.contents;
						write c;
						if(c[0] = presentGuestMessage) { 
							list<Person> guests <- c[1];
							if length(guests) > 1 {	
	
			
								loop i over: guests {
									if i.personType = "MusicLover"{
										// chekc if they are chill enough that they want to start at conversation
										if ((chill+ MusicLover(i).chill)/2 > 0.4){
											write name + "This is some really great music and it is nice to share it with another music lover " + i.name;
			
											//the more chill the people are the happineer they are talking to each other
											happiness <- happiness + (chill+ MusicLover(i).chill)/2;
										}
									}
									else if i.personType = "Partyer"{
										// chekc if they are too noisy to see if we want to start a conversation with them
										if ((chill- i.noisyLevel) > 0){
											write name + ": This is some really great music and I love to party with you "+ i.name;
			
											//the more chill we are and the less noisy the other person is the happier we will be
											happiness <- happiness + happiness*(chill- i.noisyLevel)/2;
										}
									}
									
								}
								
							}
						}
					}
					
				}
			}
		}
	}
}

}

species Partyer parent:Person{
	image_file icon <- image_file("../includes/party.png");
	string personType <- "Partyer";
	
	float musicScore <- 0.0;
	
	//The partiers personality traits
	float drunk <- rnd(0.2,0.8);
	float noisyLevel <- rnd(0.6,1.0);
	float deaf <- rnd(0.3, 1.0);
	float musicPreference <- rnd(0.4,0.7);
	
	
	
	reflex AskForMusicInfo when:!empty(informs){ // here we check what music is being played at the concert
		loop i over: informs{
			
			list<unknown> musicValue <- i.contents;
			list<float> musicValueList <- musicValue[1];

			if(musicValue[0] = musicInfo){
		
				float chill_value <- musicValueList[0];
				float rock_value <- musicValueList[1];
				float sound_value <- musicValueList[2];
				float pop_value <-musicValueList[3];
				
				// calculate the total music score
				// the more deaf, drunk and noisy we are the higher the score
				rock_value <- rock_value * (1+deaf);
				sound_value <- sound_value * (1+deaf+noisyLevel+drunk);
				pop_value <- pop_value * (1+deaf);
				
				// The chill value of the music will be value quite low by the partier
				chill_value <- chill_value *(noisyLevel);
				
				musicScore <- (chill_value + rock_value + sound_value + pop_value) ;
				if musicScore < musicPreference {
					// we leave the concert
					write self.name + ": The music and the party is not fun enough here and I'm leaving from " + targetPlace.name ;
					happiness <- happiness - (happiness*0.5) ;
					do leavePlaceAction;	
				}
				else{
					happiness <- happiness + (musicScore);
					write self.name + " The music amazing here " + targetPlace.name ;
					
					// Find somebody to talk about music with
					loop i over: informs {
						list<unknown> c <- i.contents;

						if(c[0] = presentGuestMessage) { // find somebody 
							list<Person> guests <- c[1];
							if length(guests) > 1 {	
	
			
								loop i over: guests {
									if i.personType = "MusicLover"{
										// check if they are deaf enough so that they want to start a conversation
										if ((deaf + MusicLover(i).deaf)/2 > 0.4){
											write name + "I'm really deaf but loves to party to the music with a music lover " + i.name;
			
											//the more deaf they are the higher the score
											happiness <- happiness + (deaf+ MusicLover(i).deaf)/2;
										}
									}
									else if i.personType = "Partyer"{
										// the more deaf, drunk and noisy they are the higher the chance that we will start at conversation
										if ((noisyLevel  + drunk + deaf + i.noisyLevel + Partyer(i).drunk + Partyer(i).deaf) > 1.5){
											write name + "I'm having the best party and I love to party with you "+ i.name;
			
											//the more deaf, drunk and noisy they are the higher the score
											happiness <- happiness + (noisyLevel  + drunk + deaf + i.noisyLevel + Partyer(i).drunk + Partyer(i).deaf)/2;
										}
									}
									
								}
								
							}
						}
					}
					
				}
				}
		}
	}
	
	

}

species Thief parent:Person{
	image_file icon <- image_file("../includes/thief.png");
	string personType <- "Theif";
	
	float stealingSkill <- rnd(0.8,1.0);
	float greedy <- rnd(1.0);
	float drunk <- rnd(0.2);
	float happinessStolen <- 0.0;
	
	reflex chooseWhoToStealFrom when: inPlace and !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = presentGuestMessage) {
					list<Person> guests <- c[1];
					if length(guests) >1 {
						float highestHappiness <- 0.0;
						Person MostHappyPerson <- nil;
						
						// Find the most happy person in the place
						loop i over: guests {
							if i.happiness > highestHappiness{
								highestHappiness <- i.happiness;
								MostHappyPerson <- i;
							}	
						}
			
						// check if the thief succeds
						write name + " Trying to steal happiness from " + MostHappyPerson.name;
						if rnd(0.85)< (stealingSkill-drunk){
							write name + " stole " + (MostHappyPerson.happiness*greedy) + " Happiness from " + MostHappyPerson.name;
							MostHappyPerson.happiness <- MostHappyPerson.happiness - (MostHappyPerson.happiness*greedy);
							happinessStolen <- happinessStolen + (MostHappyPerson.happiness*greedy);
							happiness <- happinessStolen;
						}
					}
			}
		}
	}
	
	
}

species LemmeOut parent:Person{
	image_file icon <- image_file("../includes/tired.png");
	float Grumpy <- rnd(0.3, 1.0);
	float Drunk <- rnd(0.3, 1.0);
	float Shy <- rnd(0.3, 0.8);
	float happiness <- happiness;
	float noisyLevel <- rnd(0.2);
	
	string personType <- "LemmeOut";
	
	reflex FindGuestToComplainTo when: inPlace and !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = presentGuestMessage) { // find somebody who does not want to be here
				list<Person> guests <- c[1];
				if length(guests) > 1 {		
					// the more drunk and grumpy we are the less our shyness matters
					float personProbTalking <- (Drunk + Grumpy) - Shy;
					loop i over: guests {
						if i.personType = "LemmeOut"{
							// check if they are too shy to start at conversation
							if ((personProbTalking + ((LemmeOut(i).Drunk+LemmeOut(i).Grumpy) - LemmeOut(i).Shy)) > 0){
								write name + "Do you also just hate being here " + i.name + " ?" + " Yes it is an awful festival";
								//the more grumpy the people are the happineer they are talking to each other
								happiness <- happiness + (Grumpy + LemmeOut(i).Grumpy)/2;
							}
						}
						
					}
				}
			}
		}
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
				data "Happiness stolen" value: globalHappinessStolen color: #red;
			}
		}
	}
}
