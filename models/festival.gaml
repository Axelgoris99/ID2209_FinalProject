/**
* Name: festival
* Based on the internal empty template. 
* 
*
* Author: Axel Goris and Tobias Skov
* Tags: 
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
	int nbLemmeOut <- 5 ;
		
	init
	{
		create Bar number: nbBar;
		create Concert number: nbConcert;

		create Drinker number: nbDrinker;
		create Partyer number: nbPartyer;
		create MusicLover number: nbMusicLover;
		create Thief number: nbThief;
	}

}

species MeetingPlace skills:[fipa]{
	//Parent of every places we're gonna create
	//Handle people going in and out
}

species Concert parent: MeetingPlace{
	
}

species Bar parent: MeetingPlace{
	
}

species Person skills:[moving, fipa]{
	//Parent of every type of people we're gonna create
	//Handle movement of people and basic interaction (nothing specialized here) / common attributes
}

species Drinker parent:Person{
	
}

species MusicLover parent:Person{
	
}

species Partyer parent:Person{
	
}

species Thief parent:Person{
	
}

species LemmeOut parent:Person{
	
}
// ============== EXPERIMENT ============ //
experiment MyExperiment type:gui {
	output {
		display myDisplay {
			
			
		}
	}
}
	
