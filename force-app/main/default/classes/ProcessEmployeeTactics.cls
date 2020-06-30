public with sharing class ProcessEmployeeTactics { public static List<SObject> Process (String tacticName, SalesTacticalPlan__c curTacticalPlan, Integer maxResults, String userId) {
    List<SObject> relevantRecords = new List<SObject>();
    List<SObject> recommendationRecords = new List<SObject>();

    List<User> userRecord =new List<User>();
    userRecord = [select Name,Id, Next_Shift_End_Date__c,Next_Shift_Start_Date__c,Survey_Taken__c,Einstein_HiPo_Likelihood__c  from User WHERE Id = :userId];
    System.debug('user Record' + userRecord);
    System.debug('Tactic Name' + tacticName );

    switch on tacticName {
        when 'Priority Messages'  {
            if (curTacticalPlan.Tactical_Ordering__c.split(',').contains('Priority Messages')) {
                
                System.debug('Priority Messages is a chosen tactic');
                
                relevantRecords = [select Name,Description,Id, ActionReference from Recommendation WHERE Name like 'Priority%'];
                System.debug('Relevant Records: ' + relevantRecords);
                for(SObject curItem : relevantRecords){
                    curItem.put('Description',curItem.get('Description'));
                    if(curItem.get('Name')=='Priority Message: Well Being Survey')
                    { if(!userRecord[0].Survey_Taken__c){
                        System.debug('in condition survey taken');
                        //add only if survey is not taken
                        recommendationRecords.add(curItem);
                    }
                    }
                    else {
                        recommendationRecords.add(curItem);

                    }
                    
                }
                
            
            }
        }
        when 'Contact Risk'  {
            if (curTacticalPlan.Tactical_Ordering__c.split(',').contains('Contact Risk')) {
               if(userRecord[0].name== 'Mae Jemison') { //simulating one user hard coded here for illustration
                System.debug('Contact Risk is a chosen tactic');
                relevantRecords = [select Name,Description,Id, ActionReference from Recommendation WHERE Name like '%risk%'];
                System.debug('Relevant Records: ' + relevantRecords);
                for(SObject curItem : relevantRecords){
                    curItem.put('Description',curItem.get('Description'));
                    recommendationRecords.add(curItem);

                }
            }
            }
        }
        when 'Covid Shift Dates' {
            if(userRecord[0].name== 'Mae Jemison'){ //simulating a user - hard coded here for illustration
            if (curTacticalPlan.Tactical_Ordering__c.split(',').contains('Covid Shift Dates')) {
                System.debug('Covid Shift Date is a chosen tactic');
                System.debug('Your next Shift start date is '+ userRecord[0].Next_Shift_Start_Date__c);

                
                relevantRecords = [select Name,Description,Id, ActionReference from Recommendation WHERE Name like '%shift%'];
               
               String startDate= ProcessEmployeeTactics.formatDate(userRecord[0].Next_Shift_Start_Date__c);
               String endDate= ProcessEmployeeTactics.formatDate(userRecord[0].Next_Shift_End_Date__c);
                //relevantRecords[0].put('Body__c','Your next Shift start date is '+ userRecord[0].Next_Shift_Start_Date__c + 'and end date is '+userRecord[0].Next_Shift_End_Date__c);
                relevantRecords[0].put('Description','Please note that your next Shift start date is '+ startDate + ' and end date is '+endDate);
                recommendationRecords.add( relevantRecords[0]);
            }
        }
    }
        when 'Einstein HiPo Likelihood' {
            if (curTacticalPlan.Tactical_Ordering__c.split(',').contains('Einstein HiPo Likelihood')) {
                
                System.debug('Einstein HiPo Likelihood is the chosen tactic');
                relevantRecords = [select Name,Id,Description, ActionReference from Recommendation WHERE Name like 'training%'];
                system.debug('hipo relevantRecords'+relevantRecords);
                if(userRecord[0].Einstein_HiPo_Likelihood__c >80.00)
                {
                    recommendationRecords.add(relevantRecords[0]);
                    system.debug('inside hipo condition'+ userRecord[0].Einstein_HiPo_Likelihood__c );

                }


            
            }       
        }
        when else {
            System.debug('unsupported value was passed in as tacticName');
        }
    }
    System.debug('Relevant Records: ' + relevantRecords);
    return recommendationRecords;
}

public static List<Recommendation> GenerateRecommendations (List<SObject> relevantRecords, String tacticName, SalesTacticalPlan__c curTacticalPlan ) {
    List<Recommendation> recs = new List<Recommendation>(); 
    String curName ;
    String curDescription;
    String curActionRef = 'TacticalFollowup';

    if (relevantRecords != null) {
        for (SObject curItem : relevantRecords) {
        
            if (curItem.getSObjectType().getDescribe().getName() == 'Recommendation') {
               
              
                    curDescription = (String)curItem.get('Description');
                    curName=(String)curItem.get('Name');

                if ((String)curItem.get('ActionReference') != null ) {
                    curActionRef = (String)curItem.get('ActionReference');
                }
                else {
                    curActionRef = 'TacticalFollowup';
                }
            }
         
            

            Recommendation rec = new Recommendation(
                Name = curName,
                Description = curDescription ,
                //Pre-req: Create a screen flow with the name simpleFlow                        
                ActionReference =  curActionRef,
                AcceptanceLabel = 'Go',
                Tactical_Priority__c = GenerateSalesTacticalPriorities.getPriority(curTacticalPlan.Tactical_Ordering__c, tacticName),
                ContextRecordId__c = (String)curItem.Id,
                ContextId__c = (String)curItem.Id
            );
            System.debug('generated recommendation: ' + rec);
            System.debug('contextrecordId is ' + rec.ContextRecordId__c);
            recs.add(rec);
        }

    }
    system.debug('returned recommendations: '+recs);
    return recs;


}



public static String formatDate (Date dt) {
   String formatted_date;
   String month = ' '+ dt.month();
   String day = ' '+ dt.day();
   String year = ' '+ dt.year();
  
   formatted_date=month+'/'+day+ '/'+year;
  system.debug('Formatted Date from helper method'+formatted_date);

    return formatted_date;
}
}