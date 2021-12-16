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
	int nbConcert <- 2;
	int nbBar <- 2;
	//People
	int nbDrinker <- 1;
	int nbMusicLover <-0;
	int nbPartyer <- 0;
	int nbThief <- 0;
	int nbLemmeOut <- 0;	
	//Typical messages used for every communication by every agents
	string enterPlace <- "Can I come in ? Where ?";
	string leavePlace <- "Thanks and See ya !";
	string hereIsYourPlace <- "Here is your place : ";
	//A list of every places agents can meet
	list<MeetingPlace> meetingPlace <- [];
	
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
}

species Bar parent: MeetingPlace{
	// ========== ATTRIBUTES ========== //
	image_file icon <- image_file("../includes/pub.png");
	float distanceOfInfluence <- 5.0;
	rgb color <- rgb(0, 0, 255, 0.5);
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
		timeInside <- 0;
	}
	
	//This is to make sure that he goes out and once he's out, he starts to wander around and everything
	reflex goOutside when: leaving and self.location distance_to targetPoint < 5.0 {
		targetPoint <- nil;
		leaving <- false;
	}
	
	// ============== GRAPHICAL ==========
	aspect default {		
		draw icon size: 2.0;		
	}
}

species Drinker parent:Person{
	image_file icon <- image_file("../includes/drunk.png");
}

species MusicLover parent:Person{
	image_file icon <- image_file("../includes/music.png");
}

species Partyer parent:Person{
	image_file icon <- image_file("../includes/party.png");
}

species Thief parent:Person{
	image_file icon <- image_file("../includes/thief.png");
}

species LemmeOut parent:Person{
	image_file icon <- image_file("../includes/tired.png");
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
	}
}
	
