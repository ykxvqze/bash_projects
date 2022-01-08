## Privacy-preserving method for merging datasets

A proposed method for merging datasets that contain sensitive information from two different parties without revealing any identifying information to either party. The task can be accomplished via a third party, e.g. a bot, without the bot receiving any identifying info either.

### Problem description

* Two independent organizations (a governmental unit and a university) in a country are working on their own separate projects.
* Researchers at the governmental unit are analyzing a large national dataset, dataset-A, relating to citizen income and taxes.
* Researchers at the university hospital are analyzing a large nation-wide dataset-B relating to electronic medical records of patients.
* Both datasets contain sensitive information and columns such as citizen names, IDs, social security numbers, etc.
* Database-A maintainer at the governmental unit is responsible for preserving the privacy of any information that can identify individuals before it is handed to governmental researchers working on dataset-A.
* Database-B maintainer at the university is responsible for preserving the privacy of any information that can identify patients before it is handed to university researchers working on dataset-B.
* Merging both datasets can provide new insight for both the governmental unit and the university (or for some other research group).

How can the two datasets be merged without revealing any citizen's identity in any of the entries? That is, neither researchers nor database maintainers should receive any new identifying information beyond what they have.

### Proposed solution

Here is a proposed method for linking two datasets maintained by two different sources while safely guarding data privacy:

1. Database-A maintainer assigns IDs/tokens to each entry in his/her database. Independently, Database-B maintainer assigns IDs/tokens to each entry in his/her database. 
2. Both send an identifying column (e.g. citizen names) and corresponding tokens _but_ no other information to a 3rd party/bot (a program or cloud application).
3. The 3rd party (bot) runs a simple program to detect matching names and assigns these entries link_IDs.
4. The 3rd party (bot) sends back to each database maintainer separately the tokens and corresponding links_IDs that have been added.
5. Database maintainers strip all identifying information from their own datasets (e.g. original IDs, citizen names, social security numbers, etc.) replacing these with just a link_ID column.
6. Database maintainers send their now modified datasets to the researchers who will work on the combined data.

This way, neither the database maintainers, nor 3rd party (bot), nor researchers can identify any linked entry.

### Example 

#### Step-1

Dataset-A:

ID (tokenized) | Name          | Annual Income | Evaded Tax | etc.  
:--------------|:--------------|:--------------|:-----------|:------
ACF            | John Doe      | 67800         | N          | ...   
XVW            | Rebecca Smith | 143400        | Y          | ...   

Dataset-B:

ID (tokenized) | Name       | Diagnosis  | Type      | Date of Diagnosis | etc.  
:--------------|:-----------|:-----------|:----------|-------------------|:------
312Q           | Bruce Lee  | broken rib | R5        | ...               | ...   
019K           | John Doe   | diabetes   | type-2    | ...               | ...   

#### Step-2:

3rd-party (bot) receives the following upload from Database-A maintainer:

ID      | Name          
:-------|:--------------
ACF     | John Doe      
XVW     | Rebecca Smith  

3rd-party (bot) receives the following upload from Database-B maintainer:

ID      | Name          
:-------|:--------------
312Q    | Bruce Lee     
019K    | John Doe      

#### Step-3 and Step-4:

3rd-party (bot) creates link_IDs for matching entries (based on 'Name') and sends each table to its respective database maintainer separately:

ID      | link_ID       
:-------|:--------------
ACF     | LMVNJPQRT     
XVW     | TYQCNRMQR     

ID      | link_ID       
:-------|:--------------
312Q    | HBSNOQLDG     
019K    | LMVNJPQRT     

#### Step-5:

Database-A maintainer modifies his/her dataset by replacing IDs with link_IDs and removing other identifying info (e.g. 'Name'):

link_ID        | Annual Income | Evaded Tax | etc.  
:--------------|:--------------|:-----------|:------
LMVNJPQRT      | 67800         | N          | ...   
TYQCNRMQR      | 143400        | Y          | ...   

Database-B maintainer modifies his/her dataset by replacing IDs with link_IDs and removing other identifying info (e.g. 'Name'):

link_ID   | Diagnosis  | Type      | Date of Diagnosis | etc.  
:---------|:-----------|:----------|:------------------|:------
HBSNOQLDG | broken rib | R5        | ...               | ...   
LMVNJPQRT | diabetes   | type-2    | ...               | ...   

#### Step-6:

Now, the database maintainers can send their modified datasets to all the researchers.

Neither database maintainers, nor 3rd party (bot), nor researchers can identify any entry.

### Additional measures

Note that the remaining data can be masked further without jeapardizing researchers' analysis: e.g. a fixed bias can be injected to certain quantitative columns so that real values are masked without affecting overall derived distribution shapes, analysis, or conclusions. Note also that from a privacy perspective, entries in datasets should preferably be representative of clusters rather than single individuals because anomalies are always at risk of being identified even in anonymized data. For example, a reporter may easily guess the identity of a citizen whose annual income exceeds $1,000,000 and has been diagnosed with lymphoma cancer; the possibilities may be narrowed down to a few or one citizen.
