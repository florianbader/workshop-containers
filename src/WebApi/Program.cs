var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
    });
});

builder.Services.AddSingleton<BasketStore>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();
app.UseCors();

// Pizza data
var pizzas = new List<Pizza>
{
    new Pizza(
        1,
        "Margherita",
        "Classic pizza with tomato sauce, mozzarella, and basil",
        ["Tomato Sauce", "Mozzarella", "Basil", "Olive Oil"]
    ),
    new Pizza(
        2,
        "Pepperoni",
        "Spicy pepperoni with mozzarella and tomato sauce",
        ["Tomato Sauce", "Mozzarella", "Pepperoni"]
    ),
    new Pizza(
        3,
        "Quattro Formaggi",
        "Four cheese pizza with mozzarella, gorgonzola, parmesan, and fontina",
        ["Mozzarella", "Gorgonzola", "Parmesan", "Fontina"]
    ),
    new Pizza(
        4,
        "Vegetariana",
        "Vegetarian pizza with grilled vegetables",
        ["Tomato Sauce", "Mozzarella", "Bell Peppers", "Zucchini", "Eggplant", "Mushrooms"]
    ),
    new Pizza(
        5,
        "Diavola",
        "Spicy salami pizza with hot peppers",
        ["Tomato Sauce", "Mozzarella", "Spicy Salami", "Hot Peppers"]
    ),
    new Pizza(
        6,
        "Prosciutto e Funghi",
        "Ham and mushroom pizza",
        ["Tomato Sauce", "Mozzarella", "Ham", "Mushrooms"]
    ),
};

// Pizza endpoints
app.MapGet("/pizzas", () => Results.Ok(pizzas)).WithName("GetPizzas").WithOpenApi();

app.MapGet(
        "/pizzas/{id}",
        (int id) =>
        {
            var pizza = pizzas.FirstOrDefault(p => p.Id == id);
            return pizza is not null ? Results.Ok(pizza) : Results.NotFound();
        }
    )
    .WithName("GetPizzaById")
    .WithOpenApi();

// Basket endpoints
app.MapPost(
        "/basket/items",
        (BasketStore store, AddBasketItemRequest request) =>
        {
            if (pizzas.All(p => p.Id != request.PizzaId))
                return Results.NotFound("Pizza not found");

            store.AddItem(request.PizzaId, request.Quantity);
            return Results.Ok(store.GetBasket());
        }
    )
    .WithName("AddToBasket")
    .WithOpenApi();

app.MapPut(
        "/basket/items/{pizzaId}",
        (BasketStore store, int pizzaId, UpdateBasketItemRequest request) =>
        {
            if (!store.UpdateQuantity(pizzaId, request.Quantity))
                return Results.NotFound("Pizza not in basket");

            return Results.Ok(store.GetBasket());
        }
    )
    .WithName("UpdateBasketItem")
    .WithOpenApi();

app.MapDelete(
        "/basket/items/{pizzaId}",
        (BasketStore store, int pizzaId) =>
        {
            if (!store.RemoveItem(pizzaId))
                return Results.NotFound("Pizza not in basket");

            return Results.Ok(store.GetBasket());
        }
    )
    .WithName("RemoveFromBasket")
    .WithOpenApi();

app.MapGet("/basket", (BasketStore store) => Results.Ok(store.GetBasket()))
    .WithName("GetBasket")
    .WithOpenApi();

app.MapPost(
        "/basket/confirm",
        (BasketStore store) =>
        {
            var basket = store.GetBasket();
            if (basket.Items.Count == 0)
                return Results.BadRequest("Basket is empty");

            var orderId = Guid.NewGuid();
            store.Clear();
            return Results.Ok(new { OrderId = orderId, Message = "Order confirmed successfully" });
        }
    )
    .WithName("ConfirmOrder")
    .WithOpenApi();

app.Run();

// Models
record Pizza(int Id, string Name, string Description, string[] Ingredients);

record AddBasketItemRequest(int PizzaId, int Quantity);

record UpdateBasketItemRequest(int Quantity);

record BasketItem(int PizzaId, int Quantity);

record Basket(List<BasketItem> Items);

// In-memory basket store
class BasketStore
{
    private readonly Dictionary<int, int> _items = new();

    public void AddItem(int pizzaId, int quantity)
    {
        if (_items.ContainsKey(pizzaId))
            _items[pizzaId] += quantity;
        else
            _items[pizzaId] = quantity;
    }

    public bool UpdateQuantity(int pizzaId, int quantity)
    {
        if (!_items.ContainsKey(pizzaId))
            return false;

        if (quantity <= 0)
            _items.Remove(pizzaId);
        else
            _items[pizzaId] = quantity;

        return true;
    }

    public bool RemoveItem(int pizzaId)
    {
        return _items.Remove(pizzaId);
    }

    public Basket GetBasket()
    {
        return new Basket(_items.Select(kvp => new BasketItem(kvp.Key, kvp.Value)).ToList());
    }

    public void Clear()
    {
        _items.Clear();
    }
}
