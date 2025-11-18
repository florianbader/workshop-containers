// Configuration
const API_BASE_URL = '__API_BASE_URL__';

// State
let pizzas = [];
let basket = { items: [] };
let orderConfirmed = false;

// DOM Elements
const pizzaList = document.getElementById('pizzaList');
const basketItems = document.getElementById('basketItems');
const confirmOrderBtn = document.getElementById('confirmOrderBtn');
const orderSuccess = document.getElementById('orderSuccess');

// Initialize the app
async function init() {
    await loadPizzas();
    await loadBasket();
    setupEventListeners();
}

// Setup event listeners
function setupEventListeners() {
    confirmOrderBtn.addEventListener('click', confirmOrder);
}

// Load all pizzas from the API
async function loadPizzas() {
    try {
        const response = await fetch(`${API_BASE_URL}/pizzas`);
        if (!response.ok) throw new Error('Failed to load pizzas');
        
        const data = await response.json();
        pizzas = data;
        renderPizzas();
    } catch (error) {
        console.error('Error loading pizzas:', error);
        pizzaList.innerHTML = '<div class="error">Failed to load pizzas. Please make sure the API is running.</div>';
    }
}

// Load current basket from the API
async function loadBasket() {
    try {
        const response = await fetch(`${API_BASE_URL}/basket`);
        if (!response.ok) throw new Error('Failed to load basket');
        
        basket = await response.json();
        renderBasket();
    } catch (error) {
        console.error('Error loading basket:', error);
    }
}

// Render pizzas in the menu
function renderPizzas() {
    if (pizzas.length === 0) {
        pizzaList.innerHTML = '<div class="loading">No pizzas available</div>';
        return;
    }

    pizzaList.innerHTML = pizzas.map(pizza => `
        <div class="pizza-card">
            <h3>${pizza.name}</h3>
            <p class="pizza-description">${pizza.description}</p>
            <div class="pizza-ingredients">
                <strong>Ingredients:</strong>
                <div>
                    ${pizza.ingredients.map(ing => `<span class="ingredient-tag">${ing}</span>`).join('')}
                </div>
            </div>
            <button class="btn-add" onclick="addToBasket(${pizza.id})">
                Add to Basket
            </button>
        </div>
    `).join('');
}

// Render basket items
function renderBasket() {
    const basketItemsContainer = basketItems;

    if (basket.items.length === 0) {
        basketItemsContainer.innerHTML = '<p class="empty-basket">Your basket is empty</p>';
        confirmOrderBtn.disabled = true;
        return;
    }

    basketItemsContainer.innerHTML = basket.items.map(item => {
        const pizza = pizzas.find(p => p.id === item.pizzaId);
        const pizzaName = pizza ? pizza.name : `Pizza #${item.pizzaId}`;
        
        return `
            <div class="basket-item">
                <div class="basket-item-header">
                    <span class="basket-item-name">${pizzaName}</span>
                    <button class="btn-remove" onclick="removeFromBasket(${item.pizzaId})">
                        Remove
                    </button>
                </div>
                <div class="basket-item-controls">
                    <button class="quantity-btn" onclick="decreaseQuantity(${item.pizzaId})" ${item.quantity <= 1 ? 'disabled' : ''}>
                        −
                    </button>
                    <span class="quantity-display">${item.quantity}</span>
                    <button class="quantity-btn" onclick="increaseQuantity(${item.pizzaId})">
                        +
                    </button>
                </div>
            </div>
        `;
    }).join('');

    confirmOrderBtn.disabled = orderConfirmed;
}

// Add pizza to basket
async function addToBasket(pizzaId) {
    try {
        const response = await fetch(`${API_BASE_URL}/basket/items`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                pizzaId: pizzaId,
                quantity: 1
            })
        });

        if (!response.ok) throw new Error('Failed to add to basket');
        
        basket = await response.json();
        renderBasket();
    } catch (error) {
        console.error('Error adding to basket:', error);
        alert('Failed to add pizza to basket. Please try again.');
    }
}

// Increase quantity
async function increaseQuantity(pizzaId) {
    const item = basket.items.find(i => i.pizzaId === pizzaId);
    if (!item) return;

    await updateQuantity(pizzaId, item.quantity + 1);
}

// Decrease quantity
async function decreaseQuantity(pizzaId) {
    const item = basket.items.find(i => i.pizzaId === pizzaId);
    if (!item || item.quantity <= 1) return;

    await updateQuantity(pizzaId, item.quantity - 1);
}

// Update pizza quantity in basket
async function updateQuantity(pizzaId, newQuantity) {
    try {
        const response = await fetch(`${API_BASE_URL}/basket/items/${pizzaId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                quantity: newQuantity
            })
        });

        if (!response.ok) throw new Error('Failed to update quantity');
        
        basket = await response.json();
        renderBasket();
    } catch (error) {
        console.error('Error updating quantity:', error);
        alert('Failed to update quantity. Please try again.');
    }
}

// Remove pizza from basket
async function removeFromBasket(pizzaId) {
    try {
        const response = await fetch(`${API_BASE_URL}/basket/items/${pizzaId}`, {
            method: 'DELETE'
        });

        if (!response.ok) throw new Error('Failed to remove from basket');
        
        basket = await response.json();
        renderBasket();
    } catch (error) {
        console.error('Error removing from basket:', error);
        alert('Failed to remove pizza from basket. Please try again.');
    }
}

// Confirm order
async function confirmOrder() {
    if (basket.items.length === 0 || orderConfirmed) return;

    try {
        const response = await fetch(`${API_BASE_URL}/basket/confirm`, {
            method: 'POST'
        });

        if (!response.ok) throw new Error('Failed to confirm order');
        
        const result = await response.json();
        console.log('Order confirmed:', result);
        
        orderConfirmed = true;
        confirmOrderBtn.disabled = true;
        orderSuccess.classList.remove('hidden');
        
        // Clear basket UI
        basket = { items: [] };
        renderBasket();
        
        // Hide success message after 5 seconds and reset
        setTimeout(() => {
            orderSuccess.classList.add('hidden');
            orderConfirmed = false;
        }, 5000);
        
    } catch (error) {
        console.error('Error confirming order:', error);
        alert('Failed to confirm order. Please try again.');
    }
}

// Start the app when DOM is loaded
document.addEventListener('DOMContentLoaded', init);
