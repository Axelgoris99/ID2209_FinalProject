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
	int nbConcert <- 2;
	int nbBar <- 2;

	int nbDrinker <-5;
	int nbMusicLover <- 5;
	int nbPartyer <- 5;
	int nbThief <- 5;
	int nbLemmeOut <- 5;	
	
	init
	{
		create Bar number: nbBar;
		create Concert number: nbConcert;

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
	image_file icon <- nil;
	//The last float is the transparency of the place
	rgb color <- rgb(0, 0, 0, 1);
	float distanceOfInfluence <- 0.0;
	list<Person> guests <- [];
	geometry areaOfInfluence <- circle(distanceOfInfluence);
	
	// === MANAGE PEOPLE IN AND OUT === //
	reflex someoneIn when: !empty(subscribe) {
		loop s over: subscribes{
			add s.sender to: guests;
		}
	}
	
	reflex someoneOut when: !empty(inform) {
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
	image_file icon <- image_file("../includes/stage.png");
	float distanceOfInfluence <- 10.0;
	rgb color <- rgb(255, 0, 0, 0.5);
}

species Bar parent: MeetingPlace{
	image_file icon <- image_file("../includes/pub.png");
	float distanceOfInfluence <- 5.0;
	rgb color <- rgb(0, 0, 255, 0.5);
}


//Parent of every type of people we're gonna create
//Handle movement of people and basic interaction (nothing specialized here) / common attributes
species Person skills:[moving, fipa]{
	image_file icon <- nil;
	rgb color <- rgb(0, 0, 0);
	
	MeetingPlace targetPlace <- nil;
	point targetPoint <- nil;
	float distanceToEnter <- 0.0;
	
	reflex decideOnAPlaceToGo when: targetPlace = nil{
		
	}
	
	reflex wanderAround when : targetPlace = nil{
		do wander;
	}
	
	//Careful, we're looking for a specific point because even inside of a place, the agent can still move to a different place if he needs to!
	reflex moveToTarget when: targetPoint != nil{
		do goto target: targetPoint;
	}
	
	reflex enterPlace when: targetPlace != nil and self.location distance_to targetPoint < distanceToEnter {
		do start_conversation to: [targetPlace] performative: 'subscribe' contents: ["enter"];
	}
	reflex leavePlace{
		
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
	
