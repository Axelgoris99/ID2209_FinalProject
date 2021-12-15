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

	
	init
	{
		write 'test';
		
	}

}

// ============== EXPERIMENT ============ //
experiment myExperiment type:gui {
	output {
		display myDisplay {
			
			
		}
	}
}
	
