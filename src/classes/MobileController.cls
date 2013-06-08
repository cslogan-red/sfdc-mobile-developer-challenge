/* MobileController.cls
 * @Author - Chase Logan
 * @Last Modified - 6/8/2013
 * 	This controller houses the data model functionality for the mobile agent app, with almost all methods exposed specifically for Remote Action calls via JavaScript.
 * 	In the interest of time, MUCH more of this is hardcoded than I would like, future iterations should focus on retrieving object/field metadata to construct queries,
 *  as well as generally cleaning up the sort of quickly constructed nature of this class. For a challenge, this will have to do :)
 */
public class MobileController {
    
    // Constructor
    public MobileController() {}

    // method queries basic SFDC object data for display in various listviews, limited to 99 records max
    @RemoteAction
    public static List<sObject> queryObject(String objectType) {
        String soqlQuery;
        String userId = UserInfo.getUserId();
        Integer objectCount;
                
        // Construct the query
        if ( objectType != null) {
            objectType = String.escapeSingleQuotes(objectType);
            
            if ( objectType == 'Leads') {
                soqlQuery = 'select Id, Name, Product_of_Interest__c, Owner.Name from Lead ' +
                            ' where OwnerId = :userId ' +
                            '   and IsConverted = false ' +
                            '   and CreatedDate in (LAST_N_DAYS:120) ' +
                            ' order by Name asc limit 99';
            } else if ( objectType == 'Opportunities') {
                soqlQuery = 'select Id, Name, Product_of_Interest__c, Owner.Name from Opportunity ' +
                            ' where OwnerId = :userId ' +
                            '   and CreatedDate in (LAST_N_DAYS:120) ' +
                            ' order by Name asc limit 99';
            } else if ( objectType == 'Tasks') {
                soqlQuery = 'select Id, Subject, Status, Type, Priority, ' +
                            '       ActivityDate, Description from Task ' +
                            ' where OwnerId = :userId ' +
                            '   and Status != \'Completed\' ' +
                            ' order by CreatedDate asc limit 99';
            } else {
                return null;
            }
            
            return Database.query(soqlQuery);
        }
        
        return null;
    }
	
	// method queries SFDC object data for display on Product of Interest graphs
    @RemoteAction
    public static List<sObject> queryObjectForGraph(String objectType, String userId, String timeFrame) {
		String soqlQuery;
		// Construct the query
    	if ( objectType != null) {
            // Leads or Opportunities
    		objectType = String.escapeSingleQuotes(objectType);
    		if ( objectType == 'Leads') {
    			soqlQuery = 'select Id, Name, Product_of_Interest__c, Owner.Name from Lead ';
    		} else if ( objectType == 'Opportunities') {
    			soqlQuery = 'select Id, Name, Product_of_Interest__c, Owner.Name from Opportunity ';
    		} else {
    			return null;
    		}
			// Date range, defaults to 120 days if none selected
			if ( timeFrame != null && timeFrame != '' && soqlQuery != null) {
				timeFrame = String.escapeSingleQuotes(timeFrame);
	            soqlQuery += 'where CreatedDate in (' + timeFrame + ')';
	        } else {
	            soqlQuery += 'where CreatedDate in (LAST_N_DAYS:120)';
	        }
			// Context user, defaults to current user if none selected
			if ( userId != null && userId != '' && soqlQuery != null) {
				userId = String.escapeSingleQuotes(userId);
	            soqlQuery += ' and OwnerId = :userId';
	        } else {
	            userId = UserInfo.getUserId();
	            soqlQuery += ' and OwnerId = :userId';
	        }
	        // POI options limited to these five
	        soqlQuery += ' and Product_of_Interest__c in (\'Auto\', \'Homeowners\', \'Life\', \'Membership\', \'Earthquake\')';
	        // hide converted leads
	      	if ( objectType == 'Leads') {
	      		soqlQuery += ' and IsConverted = false';
	      	}
	        			 
			return Database.query(soqlQuery);
    	}
    	
        return null;
    }
    
    //method responsible for querying SFDC data of a touched graphpoint
    @RemoteAction
    public static List<sObject> queryGraphObject(String objectType, String product, String userId) {
		String soqlQuery;
	            
		// Construct the query
    	if ( objectType != null && product != null && userId != null) {
    		objectType = String.escapeSingleQuotes(objectType);
    		product = String.escapeSingleQuotes(product);
    		userId = String.escapeSingleQuotes(userId);
    		
    		if ( objectType == 'Leads') {
    			soqlQuery = 'select Id, Name, Product_of_Interest__c, Owner.Name from Lead ' +
    						' where OwnerId = :userId ' +
    						'   and IsConverted = false ' +
    						'   and CreatedDate in (LAST_N_DAYS:120) ' +
    						'   and Product_of_Interest__c = :product ' +
    						' order by Name asc limit 99';
    		} else if ( objectType == 'Opportunities') {
    			soqlQuery = 'select Id, Name, Product_of_Interest__c, Owner.Name from Opportunity ' +
    						' where OwnerId = :userId ' +
    						'   and CreatedDate in (LAST_N_DAYS:120) ' +
    						'   and Product_of_Interest__c = :product ' +
    						' order by Name asc limit 99';
    		} else {
    			return null;
    		}
	        
			return Database.query(soqlQuery);
    	}
    	
    	return null;
    }
    
    // method queries detailed object data for display on on individual record detail dialogs
    @RemoteAction
    public static List<sObject> queryObjectDetails(String objectType, String Id) {
        String soqlQuery;
		String userId = UserInfo.getUserId();
	            
		// Construct the query
    	if ( objectType != null && Id != null) {
    		objectType = String.escapeSingleQuotes(objectType);
    		Id = String.escapeSingleQuotes(Id);
    		
    		if ( objectType == 'Leads') {
    			soqlQuery = 'select Id, Name, Product_of_Interest__c, Status, LeadSource, Owner.Name, Call_Back_Phone_Type__c, Phone, Home_Phone__c, Work_Phone__c, MobilePhone from Lead ';
    		} else if ( objectType == 'Opportunities') {
    			soqlQuery = 'select Id, AccountId, Name, Product_of_Interest__c, Owner.Name, StageName, Amount, Actual_Product_Name__c from Opportunity ';
    		} else if ( objectType == 'Tasks') {
    			soqlQuery = 'select Id, Subject, Status, Type, Priority, ActivityDate, Description from Task ';
    		} else if ( objectType == 'Cases') {
    			soqlQuery = 'select Id, CaseNumber, Account.Name, Status, Owner.Name, CreatedDate from Case ';
    		} else if ( objectType == 'Customers') {
    			soqlQuery = 'select Id, Name, Membership_Number__pc, Home_Phone__c, Work_Phone__pc, PersonMobilePhone, Primary_Email__pc, Member_Since__pc, Address__pc, ' +
    						'Membership__pc, Auto__pc, Home__pc, Personal_Umbrella__pc, Preferred_Method_of_Contact__pc from Account ';		
    		} else {
    			return null;
    		}
	        
	        soqlQuery += 'where Id = :Id';
			return Database.query(soqlQuery);
    	}
    	
    	return null;
    }
    
    // method is responsible for querying notification data, Tasks within +/- 7 days that have not been completed are displayed as notifications
    @RemoteAction
    public static List<sObject> getNotifications() {
    	List<Task> tasks = new List<Task>();
    	
    	tasks = [select Id, Subject, Status, Type, Priority, ActivityDate, Description 
    			   from Task 
    			  where OwnerId = :UserInfo.getUserId()
    			    and Status not in ('Completed')
    			    and (ActivityDate in (LAST_N_DAYS:7) OR ActivityDate in (NEXT_N_DAYS:7) )];
    			 
    	return tasks;
    }
    
    // method queries a given customers open Opportunities
    @RemoteAction
    public static List<Opportunity> queryCustomerOpportunities(String customerId) {
    	List<Opportunity> opptys = new List<Opportunity>();
    	
    	if ( customerId != null && customerId != '') {
    		opptys = [select Id, AccountId, Name, Product_of_Interest__c, Owner.Name, StageName, Amount, Actual_Product_Name__c 
    		            from Opportunity
    		           where AccountId = :customerId
    		             and StageName not in ('Closed Sold', 'Closed Lost', 'Completed (Admin Use Only)', 'Closed by ELM')
    		           limit 100];
    	}
    	
    	return opptys;
    }
    
    // method queries a given opportunity's customer record
    @RemoteAction
    public static List<Account> queryOpportunityCustomer(String customerId) {
    	List<Account> customers = new List<Account>();
    	
    	if ( customerId != null && customerId != '') {
    		customers = [select Id, Name, Membership_Number__pc, Home_Phone__c, Work_Phone__pc, PersonMobilePhone, Primary_Email__pc, Member_Since__pc, Address__pc,
    						    Membership__pc, Auto__pc, Home__pc, Personal_Umbrella__pc, Preferred_Method_of_Contact__pc 
    				       from Account
    				      where Id = :customerId];
    	}
    	
    	return customers;
    }
    
    // returns the current user ID
    @RemoteAction
    public static String getCurrentUser() {
   		return UserInfo.getUserId();
    }
    
    // executes a user search
    @RemoteAction
    public static User executeSearch(String userName) {
        User u = null;
        
        if ( userName != null) {
            try {
                u = [select Id from User where Name = :userName limit 1];
            } catch (Exception e) {
                u = null;
            }
        }
        
        return u;
    }
    
    // executes a case search
    @RemoteAction
    public static List<Case> executeCaseSearch(String caseNumber, String caseOwner) {
        List<Case> cases = new List<Case>();
    	
        if ( (caseNumber == null || caseNumber.length() < 4) && caseOwner == null ) {
            return null;
        } else if ( (caseNumber == null || caseNumber.length() < 4) && caseOwner != null ) {
        	caseOwner = String.escapeSingleQuotes(caseOwner);
        	String caseFilter = '%' + caseOwner + '%';
        
	        cases = [select Id, CaseNumber, Account.Name
	                   from Case
	                  where Owner.Name like :caseFilter
	                  order by Account.Name
                      limit 99];
	        
	        if ( cases.size() == 0 ) {
	            return null;
	        }
        } else if ( caseNumber != null || caseNumber.length() > 4) {
        	caseNumber = String.escapeSingleQuotes(caseOwner);
        	String caseNumberFilter = '%' + caseNumber + '%';
        
	        cases = [select Id, CaseNumber, Account.Name
	                   from Case
	                  where CaseNumber like :caseNumberFilter
	                  order by Account.Name
                      limit 99];
	        
	        if ( cases.size() == 0 ) {
	            return null;
	        }
        }
        
        return cases;
    }
    
    // executes a customer search
    @RemoteAction
    public static List<Account> executeCustomerSearch(String memberNumber, string customerName) {
    	List<Account> customers = new List<Account>();
    	
    	if ( (memberNumber == null || memberNumber.length() < 14) && customerName == null) {
    		return null;
    	} else if ( (memberNumber == null || memberNumber.length() < 14) && customerName != null) {
    		customerName = String.escapeSingleQuotes(customerName);
    		String customerFilter = '%' + customerName + '%';
    		
    		customers = [select Id, PersonMobilePhone, Home_Phone__c, Work_Phone__pc, Name, Address__pc, Primary_Email__pc, Preferred_Method_of_Contact__pc,
    					 		PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, Membership_Number__pc, FirstName, LastName
    					   from Account
    					  where Name like :customerFilter
    					  order by Name limit 99];
    		
    		if ( customers.size() == 0) {
    			return null;
    		}
    	} else if ( memberNumber != null && memberNumber.length() >= 14) {
    		memberNumber = String.escapeSingleQuotes(memberNumber);
    		String numberFilter = memberNumber + '%';
    		
    		customers = [select Id, PersonMobilePhone, Home_Phone__c, Work_Phone__pc, Name
    					   from Account
    					  where Membership_Number__pc like :numberFilter
    					  order by Name limit 99];
    		
    		if ( customers.size() == 0) {
    			return null;
    		}
    	}
    	
    	return customers;
    }
    
    // Method responsible for updating/deleting/converting various SFDC objects
    @RemoteAction
    public static Boolean modifyObject(String objectType, String action, sObject theObject) {
    	Lead leadToModify;
    	Opportunity opptyToModify;
    	Account customerToModify;
    	Task taskToModify;
    	Boolean isSuccess = false;
    	
    	if ( theObject != null && objectType != null && objectType != '' && objectType == 'lead' ) {
    		if ( action != null && action != '' && action == 'convert') {
    			leadToModify = new Lead(Id = theObject.Id);
	    		leadToModify.Status = 'Interested';
	    		
	    		isSuccess = true;
	    		try {
	    			update leadToModify;
	    		} catch (Exception e) {
	    			isSuccess = false;
	    		}
    		} else if ( action != null && action != '' && action == 'edit') {
    			leadToModify = new Lead(Id = theObject.Id);
    			leadToModify.Call_Back_Phone_Type__c = (( (String)theObject.get('Call_Back_Phone_Type__c') != null && (String)theObject.get('Call_Back_Phone_Type__c') != '') ? (String)theObject.get('Call_Back_Phone_Type__c') : leadToModify.Call_Back_Phone_Type__c );
    			leadToModify.Product_of_Interest__c = (( (String)theObject.get('Product_of_Interest__c') != null && (String)theObject.get('Product_of_Interest__c') != '') ? (String)theObject.get('Product_of_Interest__c') : leadToModify.Product_of_Interest__c );
    			leadToModify.Status = (( (String)theObject.get('Status') != null && (String)theObject.get('Status') != '') ? (String)theObject.get('Status') : leadToModify.Status );
    			leadToModify.Home_Phone__c = (( (String)theObject.get('Home_Phone__c') != null && (String)theObject.get('Home_Phone__c') != '') ? (String)theObject.get('Home_Phone__c') : leadToModify.Home_Phone__c );
    			leadToModify.Work_Phone__c = (( (String)theObject.get('Work_Phone__c') != null && (String)theObject.get('Work_Phone__c') != '') ? (String)theObject.get('Work_Phone__c') : leadToModify.Work_Phone__c );
    			leadToModify.MobilePhone = (( (String)theObject.get('MobilePhone') != null && (String)theObject.get('MobilePhone') != '') ? (String)theObject.get('MobilePhone') : leadToModify.MobilePhone );
    			
    			isSuccess = true;
    			try {
    				update leadToModify;
	    		} catch (Exception e) {
	    			isSuccess = false;
	    		}
    		} else if ( action != null && action != '' && action == 'delete') {
    			leadToModify = new Lead(Id = theObject.Id);
    		
	    		isSuccess = true;
	    		try {
	    			delete leadToModify;
	    		} catch (Exception e) {
	    			isSuccess = false;
	    		}
    		}
    	} else if ( theObject != null && objectType != null && objectType != '' && objectType == 'customer' ) {
    		if ( action != null && action != '' && action == 'edit') {
    			customerToModify = new Account(Id = theObject.Id);
    			
    			customerToModify.Preferred_Method_of_Contact__pc = (( (String)theObject.get('Preferred_Method_of_Contact__pc') != null && (String)theObject.get('Preferred_Method_of_Contact__pc') != '') ? (String)theObject.get('Preferred_Method_of_Contact__pc') : customerToModify.Preferred_Method_of_Contact__pc );
    			customerToModify.Home_Phone__c = (( (String)theObject.get('Home_Phone__c') != null && (String)theObject.get('Home_Phone__c') != '') ? (String)theObject.get('Home_Phone__c') : customerToModify.Home_Phone__c );
    			customerToModify.Work_Phone__pc = (( (String)theObject.get('Work_Phone__pc') != null && (String)theObject.get('Work_Phone__pc') != '') ? (String)theObject.get('Work_Phone__pc') : customerToModify.Work_Phone__pc );
    			customerToModify.PersonMobilePhone = (( (String)theObject.get('PersonMobilePhone') != null && (String)theObject.get('PersonMobilePhone') != '') ? (String)theObject.get('PersonMobilePhone') : customerToModify.PersonMobilePhone );
    			customerToModify.Primary_Email__pc = (( (String)theObject.get('Primary_Email__pc') != null && (String)theObject.get('Primary_Email__pc') != '') ? (String)theObject.get('Primary_Email__pc') : customerToModify.Primary_Email__pc );
    			
    			isSuccess = true;
    			try {
    				update customerToModify;
	    		} catch (Exception e) {
	    			isSuccess = false;
	    		}
    		}
    	}
    	
    	return isSuccess;
    }

    // Method handles creating SFDC objects based on a clicked product of interest icon on the customer detail page
    @RemoteAction
    public static List<sObject> createPOIObject(String objectType, String customerName, String product) {
        List<Account> customers = new List<Account>();
        String id;
        
        if ( (objectType != null && objectType != '' && customerName != null && customerName != '') && objectType == 'Leads') {
            customers = executeCustomerSearch(null, customerName);
            
            if ( customers != null && customers.size() > 0) {
                Account correctCustomer = new Account();
                for ( Account cust : customers) {
                    if ( cust.Name == customerName) {
                        correctCustomer = cust;
                    }
                }
                
                if ( correctCustomer != null) {
                    Lead myLead = new Lead();
                    myLead.FirstName = correctCustomer.FirstName;
                    myLead.LastName = correctCustomer.LastName;
                    myLead.Call_Back_Phone_Type__c = ((correctCustomer.Preferred_Method_of_Contact__pc != null && correctCustomer.Preferred_Method_of_Contact__pc != '') ? correctCustomer.Preferred_Method_of_Contact__pc : 'Home');
                    myLead.Home_Phone__c = ((correctCustomer.Home_Phone__c != null && correctCustomer.Home_Phone__c != '') ? correctCustomer.Home_Phone__c : '');
                    myLead.Work_Phone__c = ((correctCustomer.Work_Phone__pc != null && correctCustomer.Work_Phone__pc != '') ? correctCustomer.Work_Phone__pc : '');
                    myLead.MobilePhone = ((correctCustomer.PersonMobilePhone != null && correctCustomer.PersonMobilePhone != '') ? correctCustomer.PersonMobilePhone : '');
                    myLead.Email = ((correctCustomer.Primary_Email__pc != null && correctCustomer.Primary_Email__pc != '') ? correctCustomer.Primary_Email__pc : '');
                    myLead.Membership_Number__c = ((correctCustomer.Membership_Number__pc != null && correctCustomer.Membership_Number__pc != '' && correctCustomer.Membership_Number__pc.length() == 16) ? correctCustomer.Membership_Number__pc : '');
                    myLead.Street = ((correctCustomer.PersonMailingStreet != null && correctCustomer.PersonMailingStreet != '') ? correctCustomer.PersonMailingStreet : '');
                    myLead.City = ((correctCustomer.PersonMailingCity != null && correctCustomer.PersonMailingCity != '') ? correctCustomer.PersonMailingCity : '');
                    myLead.State = ((correctCustomer.PersonMailingState != null && correctCustomer.PersonMailingState != '') ? correctCustomer.PersonMailingState : '');
                    myLead.PostalCode = ((correctCustomer.PersonMailingPostalCode != null && correctCustomer.PersonMailingPostalCode != '') ? correctCustomer.PersonMailingPostalCode : '');
                    myLead.LeadSource = 'Agent Activity';
                    myLead.Product_of_Interest__c = ((product != null && product != '') ? product : 'Membership');
                    myLead.Status = 'New';
                    insert myLead;
                    id = myLead.Id;
                }
            }
            return queryObjectDetails('Leads', id);
        } 
        
        return null;
    }
    
    // Method creates a new Lead based on the data the user has entered, validation is performed client side
    @RemoteAction
    public static List<sObject> createLead(Lead theLead) {
    	if ( theLead != null) {
    		Lead myLead = new Lead();
			myLead.FirstName = (String)theLead.get('FirstName');
			myLead.LastName = (String)theLead.get('LastName');
			myLead.Call_Back_Phone_Type__c = (String)theLead.get('Call_Back_Phone_Type__c');
			myLead.Home_Phone__c = (((String)theLead.get('Call_Back_Phone_Type__c') == 'Home') ? (String)theLead.get('Phone') : '');
			myLead.Work_Phone__c = (((String)theLead.get('Call_Back_Phone_Type__c') == 'Work') ? (String)theLead.get('Phone') : '');
			myLead.MobilePhone = (((String)theLead.get('Call_Back_Phone_Type__c') == 'Mobile') ? (String)theLead.get('Phone') : '');
			myLead.Email = (((String)theLead.get('Email') != null && (String)theLead.get('Email') != '') ? (String)theLead.get('Email')  : '');
			myLead.Street = (String)theLead.get('Street');
			myLead.City = (String)theLead.get('City');
			myLead.State = (String)theLead.get('State');
			myLead.PostalCode = (String)theLead.get('PostalCode');
			myLead.LeadSource = 'Agent Activity';
			myLead.Product_of_Interest__c = (String)theLead.get('Product_of_Interest__c');
			myLead.Status = (String)theLead.get('Status');
			insert myLead;
			String id = myLead.Id;
			
			return queryObjectDetails('Leads', id);
    	}
    	return null;
    }
    
    // Method handles creating tasks for Leads or Opportunities, validation is performed client side
    @RemoteAction
    public static List<sObject> createTask(String theTaskDate, Task theTask) {
    	if ( theTask != null) {
    		Task myTask = new Task();
    		if ( (String)theTask.get('WhoId') != null && (String)theTask.get('WhoId') != '' ) {
    			myTask.WhoId = (String)theTask.get('WhoId');
    		} else if ( (String)theTask.get('WhatId') != null && (String)theTask.get('WhatId') != '' ) {
    			myTask.WhatId = (String)theTask.get('WhatId');
    		}
    		myTask.Type = (String)theTask.get('Type');
    		myTask.Subject = (String)theTask.get('Subject');
    		myTask.Status = (String)theTask.get('Status');
    		myTask.Description = (((String)theTask.get('Description') != null && (String)theTask.get('Description') != '') ? (String)theTask.get('Description') : '');
    		myTask.ActivityDate = (( theTaskDate != null && theTaskDate != '') ? Date.parse(theTaskDate) : Date.today() );
    		myTask.Priority = (String)theTask.get('Priority');
    		insert myTask;
    		String id = myTask.Id;
    		
    		return queryObjectDetails('Tasks', id);
    	}

    	return null;
    }

    // method handles updating a Task record
    @RemoteAction
    public static boolean updateTask(String theTaskDate, Task theTask) {
        Boolean isSuccess = false;
        if ( theTask != null) {
            Task taskToModify = new Task(Id = theTask.Id);
            
            taskToModify.Status = (String)theTask.get('Status');
            taskToModify.Subject = (String)theTask.get('Subject');
            taskToModify.Description = (String)theTask.get('Description');
            taskToModify.Type = (String)theTask.get('Type');
            taskToModify.ActivityDate = (( theTaskDate != null && theTaskDate != '') ? Date.parse(theTaskDate) : Date.today() );
            taskToModify.Priority = (String)theTask.get('Priority');
            
            isSuccess = true;
            try {
                update taskToModify;
            } catch (Exception e) {
                isSuccess = false;
            }
        }

        return isSuccess;
    }
    
    // Method returns a map containing all picklist values for each object that has a picklist to display on edit dialog
    @RemoteAction
    public static Map<String,List<String>> getPickListVals() {
    	Map<String,List<String>> returnVals = new Map<String,List<String>>();
    	
    	// Lead.Product_of_Interest__c
    	Schema.DescribeFieldResult fieldResult = Lead.Product_Of_Interest__c.getDescribe();
        returnVals.put('leadPOI',constructPickVals( fieldResult));
        
        // Lead.Status
    	fieldResult = Lead.Status.getDescribe();
        returnVals.put('leadStatus',constructPickVals( fieldResult));
        
        // Lead.Call_Back_Phone_Type__c
    	fieldResult = Lead.Call_Back_Phone_Type__c.getDescribe();
        returnVals.put('leadCallBackPhoneType',constructPickVals( fieldResult));
        
        // Account.Preferred_Method_of_Contact__pc
    	fieldResult = Account.Preferred_Method_of_Contact__pc.getDescribe();
        returnVals.put('customerCallBackPhoneType',constructPickVals( fieldResult));
        
        // Task.Status
    	fieldResult = Task.Status.getDescribe();
        returnVals.put('taskStatus',constructPickVals( fieldResult));
        
        // Task.Type
    	fieldResult = Task.Type.getDescribe();
        returnVals.put('taskType',constructPickVals( fieldResult));
        
        // Task.Priority
    	fieldResult = Task.Priority.getDescribe();
        returnVals.put('taskPriority',constructPickVals( fieldResult));
        
        return returnVals;
    }

    // handles constructing the pickVals String List
    private static List<String> constructPickVals( Schema.DescribeFieldResult fieldResult) {
        List<String> pickVals = new List<String>();
        if ( fieldResult != null) {
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for ( Schema.Picklistentry p : ple) {
                String myVal = p.getValue();
                pickVals.add( myVal);
            }
        }
        return pickVals;
    }
    
}