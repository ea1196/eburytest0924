import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getExchangeRate from '@salesforce/apex/NewTradeController.getExchangeRate';
import createTrade from '@salesforce/apex/NewTradeController.createNewTrade';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; // For showing success/error messages

export default class NewTrade extends NavigationMixin(LightningElement) {
    @track sellCurrency = '';
    @track buyCurrency = '';
    @track sellAmount = 0;
    @track buyAmount = 0;
    @track rate = 0;

    currencyOptions = [
        { label: 'USD', value: 'USD' },
        { label: 'EUR', value: 'EUR' },
        { label: 'GBP', value: 'GBP' },
    ];

    handleSellCurrencyChange(event) {
        this.sellCurrency = event.detail.value;
        this.fetchRate();
    }

    handleBuyCurrencyChange(event) {
        this.buyCurrency = event.detail.value;
        this.fetchRate();
    }

    handleSellAmountChange(event) {
        this.sellAmount = event.detail.value;
        this.buyAmount = this.sellAmount * this.rate;
    }

    fetchRate() {
        if (this.sellCurrency && this.buyCurrency) {
            getExchangeRate({ sellCurrency: this.sellCurrency, buyCurrency: this.buyCurrency })
                .then(result => {
                    this.rate = result;
                    this.buyAmount = this.sellAmount * this.rate;
                })
                .catch(error => {
                    this.showErrorToast('Error fetching rate', error.body.message);
                });
        }
    }

    createTrade() {
        if (this.sellAmount <= 0) {
            this.showErrorToast('Invalid Input', 'Sell Amount must be greater than zero.');
            return;
        }
        if (!this.sellCurrency || !this.buyCurrency) {
            this.showErrorToast('Invalid Input', 'Currency fields cannot be empty.');
            return;
        }
    
        createTrade({
            sellCurrency: this.sellCurrency, 
            sellAmount: this.sellAmount, 
            buyCurrency: this.buyCurrency
        })
        .then(result => {
            this.showSuccessToast('Trade created successfully');
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: result.Id,
                    actionName: 'view',
                },
            });
        })
        .catch(error => {
            console.error('Error creating trade:', error);
            this.showErrorToast('Error creating trade', error.body.message || 'Unknown error');
        });
    }
    

    // Handle 'Cancel' button click to navigate back to the appropriate page in your custom application
    closePage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Trade__c',
                actionName: 'list'
            },
            state: {
                filterName: 'All' 
            }
        });
    }

    // Method to show success toast
    showSuccessToast(title) {
        const evt = new ShowToastEvent({
            title: title,
            message: 'The trade has been created successfully.',
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    // Method to show error toast
    showErrorToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }
}
