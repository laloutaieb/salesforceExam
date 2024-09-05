import { LightningElement, wire, track } from 'lwc';
import getParties from '@salesforce/apex/PartyController.getParties';
import getCurrentUserInfo from '@salesforce/apex/UserController.getCurrentUserInfo';
import saveChoice from '@salesforce/apex/ChoiceController.saveChoice';
import createParty from '@salesforce/apex/PartyController.createParty'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PartySelection extends LightningElement {
    @track parties = [];
    @track selectedPartyId;
    @track customText = ''; 
    @track showCustomTextField = false;
    @track userId;
    @track userName;
    @track missingButton = false;

    @track partyName = '';
    @track partyCode = '';
    @track partyDescription = '';
    @track partyLeader = '';

    @wire(getParties)
    wiredParties({ error, data }) {
        if (data) {
            this.parties = data;
        } else if (error) {
            console.error('Error fetching parties:', error);
        }
    }

    @wire(getCurrentUserInfo)
    wiredUserInfo({ error, data }) {
        if (data) {
            this.userId = data.userId;
            this.userName = data.userName;
        } else if (error) {
            console.error('Error fetching user info:', error);
        }
    }

    handleCardClick(event) {
        const partyId = event.currentTarget.dataset.id;
        this.selectedPartyId = partyId;
        this.showCustomTextField = false;
    }

    handleCustomTextChange(event) {
        const fieldName = event.target.name;
        this[fieldName] = event.target.value;
    }

    handleMissingClick(event) {
        this.missingButton = !this.missingButton;
    }

    handleSave() {
        if (this.missingButton) {
      
            this.createParty()
            .then((result) => {
                console.log('New party created with ID: ', result);
                this.selectedPartyId = result;  
                return this.saveChoice();  
            })
            .then(() => {
                this.showToast('Success', 'Your choice has been saved successfully.', 'success');
            })
            .catch(error => {
                this.showToast('Error', 'There was an error creating the party or saving the choice.', 'error');
                console.error('Error:', error);
            });
        } else if (this.userId && this.selectedPartyId) {
 
            this.saveChoice()
            .then(() => {
                this.showToast('Success', 'Your choice has been saved successfully.', 'success');
            })
            .catch(error => {
                this.showToast('Error', 'There was an error saving your choice.', 'error');
                console.error('Error saving choice:', error);
            });
        } else {
            this.showToast('Error', 'Party or User ID not found.', 'error');
        }
    }

    createParty() { 
        return createParty({
            name: this.partyName,
            code: this.partyCode,
            description: this.partyDescription,
            leader: this.partyLeader,
        })
        .then(result => {
            if (result) {
                console.log('Party created with ID: ', result);
                return result; 
            } else {
                console.error('Party creation returned undefined result');
                this.showToast('Error', 'There was an issue with party creation.', 'error');
                throw new Error('Party creation failed');
            }
        })
        .catch(error => {
            this.showToast('Error', 'There was an error creating the party.', 'error');
            console.error('Error creating party:', error);
            throw error; 
        });
    }

    saveChoice() {
        return saveChoice({
            partyId: this.selectedPartyId,
            userId: this.userId,
            userName: this.userName,
            choiceDate: new Date(),
        })
        .then(result => {
            this.selectedPartyId = null; 
            this.showCustomTextField = false;
        })
        .catch(error => {
            this.showToast('Error', 'There was an error saving your choice.', 'error');
            console.error('Error saving choice:', error);
            throw error; 
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}
