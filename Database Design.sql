DROP TABLE IF EXISTS Delivery_Items      CASCADE;
DROP TABLE IF EXISTS Deliveries          CASCADE;
DROP TABLE IF EXISTS Transaction_Items   CASCADE;
DROP TABLE IF EXISTS Payments            CASCADE;
DROP TABLE IF EXISTS Order_Items         CASCADE;
DROP TABLE IF EXISTS Orders              CASCADE;
DROP TABLE IF EXISTS Inventory           CASCADE;
DROP TABLE IF EXISTS Shifts              CASCADE;
DROP TABLE IF EXISTS Promotions          CASCADE;
DROP TABLE IF EXISTS Vendor_Products     CASCADE;
DROP TABLE IF EXISTS Sales_Transactions  CASCADE;
DROP TABLE IF EXISTS Customers           CASCADE;
DROP TABLE IF EXISTS Employees           CASCADE;
DROP TABLE IF EXISTS Products            CASCADE;
DROP TABLE IF EXISTS Vendors             CASCADE;
DROP TABLE IF EXISTS Stores              CASCADE;


CREATE TABLE Stores (
    store_id 		SERIAL 			PRIMARY KEY,
    name 			VARCHAR(100) 	NOT NULL,
    address 		VARCHAR(255),
    opening_date 	DATE   
);

CREATE TABLE Products (
    product_id 		SERIAL 			PRIMARY KEY,
    name 			VARCHAR(100) 	NOT NULL,
    category 		VARCHAR(50),
    unit_price 		NUMERIC(10, 2) 	NOT NULL,
    stock_unit 		VARCHAR(20)
);

CREATE TABLE Vendors (
    vendor_id 		SERIAL 			PRIMARY KEY,
    name 			VARCHAR(100) 	NOT NULL,
    contact_info 	VARCHAR(255),
    rating 			NUMERIC(2, 1)
);

CREATE TABLE Vendor_Products (
    id        		SERIAL 			PRIMARY KEY,
    vendor_id  		INT 			NOT NULL,
    product_id 		INT 			NOT NULL,
    FOREIGN KEY (vendor_id)  REFERENCES Vendors(vendor_id) 		ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id) 	ON DELETE CASCADE,
	UNIQUE (vendor_id, product_id)
);

CREATE TABLE Employees (
    employee_id 	SERIAL 			PRIMARY KEY,
    first_name  	VARCHAR(50) 	NOT NULL,
    last_name		VARCHAR(50) 	NOT NULL,
    role			VARCHAR(50),
    hire_date		DATE,
	leave_date 		DATE,
    store_id    	INT,
    FOREIGN KEY (store_id) REFERENCES Stores(store_id) ON DELETE SET NULL
);

CREATE TABLE Customers (
    customer_id 	SERIAL 			PRIMARY KEY,
    first_name 		VARCHAR(50) 	NOT NULL,
    last_name 		VARCHAR(50) 	NOT NULL,
    email 			VARCHAR(100) 	UNIQUE,
    phone_number 	VARCHAR(50),
    membership_level VARCHAR(50) 	DEFAULT 'Standard'
);

CREATE TABLE Sales_Transactions (
    transaction_id	SERIAL 			PRIMARY KEY,
    store_id		INT 			NOT NULL,
    employee_id     INT				NOT NULL,
    customer_id     INT,
    transaction_date TIMESTAMP 		NOT NULL,
    total_amount	NUMERIC(10,2) 	NOT NULL,
    FOREIGN KEY (store_id)    REFERENCES Stores(store_id) ON DELETE RESTRICT,
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) ON DELETE SET NULL,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id) ON DELETE SET NULL
);

CREATE TABLE Transaction_Items (
	id             	SERIAL 			PRIMARY KEY,
    transaction_id 	INT 			NOT NULL,
    product_id     	INT 			NOT NULL,
    quantity      	INT 			NOT NULL,
    unit_price     	NUMERIC(10,2) 	NOT NULL,
    FOREIGN KEY (transaction_id) REFERENCES Sales_Transactions(transaction_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id)     REFERENCES Products(product_id) ON DELETE RESTRICT,
	UNIQUE (transaction_id, product_id)
);

CREATE TABLE Orders (
    order_id   		SERIAL 			PRIMARY KEY,
    vendor_id  		INT 			NOT NULL,
    order_date 		DATE 			NOT NULL,
    status     		VARCHAR(20) 	DEFAULT 'Pending',
    FOREIGN KEY (vendor_id) REFERENCES Vendors(vendor_id) ON DELETE RESTRICT
);

CREATE TABLE Order_Items (
    id         		SERIAL 			PRIMARY KEY,
    order_id   		INT 			NOT NULL,
    product_id 		INT 			NOT NULL,
    quantity   		INT 			NOT NULL,
    unit_price 		NUMERIC(10,2) 	NOT NULL,
    FOREIGN KEY (order_id)   REFERENCES Orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE RESTRICT
);

CREATE TABLE Deliveries (
    delivery_id   	SERIAL     		PRIMARY KEY,
    order_id      	INT        		NOT NULL,
    store_id      	INT        		NOT NULL,
    delivered_at  	TIMESTAMP  		NOT NULL,
    status        	VARCHAR(20),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (store_id) REFERENCES Stores(store_id) ON DELETE RESTRICT
);

CREATE TABLE Delivery_Items (
    id                 SERIAL 		PRIMARY KEY,
    delivery_id        INT 			NOT NULL,
    order_item_id      INT 			NOT NULL,
    quantity_delivered INT 			NOT NULL,
    FOREIGN KEY (delivery_id)  REFERENCES Deliveries(delivery_id) ON DELETE CASCADE,
    FOREIGN KEY (order_item_id) REFERENCES Order_Items(id)        ON DELETE RESTRICT,
    UNIQUE (delivery_id, order_item_id)
);

CREATE TABLE Inventory (
    inventory_id 	SERIAL 			PRIMARY KEY,
    store_id     	INT 			NOT NULL,
    product_id   	INT 			NOT NULL,
    quantity     	INT 			NOT NULL DEFAULT 0,
    last_updated 	DATE 			DEFAULT CURRENT_DATE,
    FOREIGN KEY (store_id)   REFERENCES Stores(store_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE,
	UNIQUE (store_id, product_id)
);

CREATE TABLE Shifts (
	shift_id   		SERIAL 			PRIMARY KEY,
    employee_id 	INT 			NOT NULL,
    store_id    	INT 			NOT NULL,
    start_time    	TIMESTAMP 		NOT NULL,
    end_time      	TIMESTAMP 		NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) ON DELETE CASCADE,
    FOREIGN KEY (store_id)    REFERENCES Stores(store_id) ON DELETE CASCADE
);

CREATE TABLE Payments (
    payment_id     	SERIAL 			PRIMARY KEY,
    transaction_id 	INT 			NOT NULL,
    payment_method 	VARCHAR(50) 	NOT NULL,
    amount         	NUMERIC(10,2) 	NOT NULL,
    payment_date   	TIMESTAMP,
	status         	VARCHAR(20) 	DEFAULT 'captured',  -- 'captured','void','refunded','pending'
    FOREIGN KEY (transaction_id) REFERENCES Sales_Transactions(transaction_id) ON DELETE CASCADE
);

CREATE TABLE Promotions (
    promo_id      	SERIAL 			PRIMARY KEY,
    product_id    	INT 			NOT NULL,
    discount_rate 	NUMERIC(4,2),
    start_date    	DATE 			NOT NULL,
    end_date      	DATE 			NOT NULL,
    FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE
);

----------------------------- Triggers -----------------------------

CREATE OR REPLACE FUNCTION check_inventory_quantity_not_negative()
RETURNS TRIGGER AS $$
	BEGIN
	    IF NEW.quantity < 0 THEN
    	    RAISE EXCEPTION 'Inventory cannot be negative for % (attempted: %)', TG_TABLE_NAME, NEW.quantity;
    	END IF;
    	RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS inventory_quantity_not_negative_trigger ON Inventory;

CREATE TRIGGER inventory_quantity_not_negative_trigger
BEFORE INSERT OR UPDATE ON Inventory
FOR EACH ROW
EXECUTE FUNCTION check_inventory_quantity_not_negative();

--> SALES: subtract inventory when items are sold

CREATE OR REPLACE FUNCTION inv_on_tx_items()
	RETURNS TRIGGER AS $$
	DECLARE
	  s INT;  -- store
	BEGIN
	  IF TG_OP = 'INSERT' THEN
    	SELECT store_id INTO s FROM Sales_Transactions WHERE transaction_id = NEW.transaction_id;
    -- subtract; make row if missing
    	UPDATE Inventory SET quantity = quantity - NEW.quantity, last_updated = CURRENT_DATE
      	WHERE store_id = s AND product_id = NEW.product_id;
    	IF NOT FOUND THEN
      	INSERT INTO Inventory (store_id, product_id, quantity, last_updated)
      	VALUES (s, NEW.product_id, 0, CURRENT_DATE);
      	UPDATE Inventory SET quantity = quantity - NEW.quantity, last_updated = CURRENT_DATE
        	WHERE store_id = s AND product_id = NEW.product_id;
    	END IF;
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    SELECT store_id INTO s FROM Sales_Transactions WHERE transaction_id = OLD.transaction_id;
    UPDATE Inventory SET quantity = quantity + OLD.quantity, last_updated = CURRENT_DATE
      WHERE store_id = s AND product_id = OLD.product_id;
    RETURN OLD;

  ELSE  -- UPDATE: add back old, subtract new (covers store/product change too)
    SELECT store_id INTO s FROM Sales_Transactions WHERE transaction_id = OLD.transaction_id;
    UPDATE Inventory SET quantity = quantity + OLD.quantity, last_updated = CURRENT_DATE
      WHERE store_id = s AND product_id = OLD.product_id;

    SELECT store_id INTO s FROM Sales_Transactions WHERE transaction_id = NEW.transaction_id;
    UPDATE Inventory SET quantity = quantity - NEW.quantity, last_updated = CURRENT_DATE
      WHERE store_id = s AND product_id = NEW.product_id;
    IF NOT FOUND THEN
      INSERT INTO Inventory (store_id, product_id, quantity, last_updated)
      VALUES (s, NEW.product_id, 0, CURRENT_DATE);
      UPDATE Inventory SET quantity = quantity - NEW.quantity, last_updated = CURRENT_DATE
        WHERE store_id = s AND product_id = NEW.product_id;
    END IF;
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_tx_items_inv ON Transaction_Items;
CREATE TRIGGER trg_tx_items_inv
AFTER INSERT OR UPDATE OR DELETE ON Transaction_Items
FOR EACH ROW EXECUTE FUNCTION inv_on_tx_items();

--> RECEIPTS: add inventory when items are delivered

CREATE OR REPLACE FUNCTION inv_on_delivery_items()
RETURNS TRIGGER AS $$
DECLARE
  s INT;   -- store
  p INT;   -- product
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT d.store_id INTO s FROM Deliveries d WHERE d.delivery_id = NEW.delivery_id;
    SELECT oi.product_id INTO p FROM Order_Items oi WHERE oi.id = NEW.order_item_id;

    UPDATE Inventory SET quantity = quantity + NEW.quantity_delivered, last_updated = CURRENT_DATE
      WHERE store_id = s AND product_id = p;
    IF NOT FOUND THEN
      INSERT INTO Inventory (store_id, product_id, quantity, last_updated)
      VALUES (s, p, NEW.quantity_delivered, CURRENT_DATE);
    END IF;
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    SELECT d.store_id INTO s FROM Deliveries d WHERE d.delivery_id = OLD.delivery_id;
    SELECT oi.product_id INTO p FROM Order_Items oi WHERE oi.id = OLD.order_item_id;

    UPDATE Inventory SET quantity = quantity - OLD.quantity_delivered, last_updated = CURRENT_DATE
      WHERE store_id = s AND product_id = p;
    RETURN OLD;

  ELSE  -- UPDATE
    -- remove old
    SELECT d.store_id INTO s FROM Deliveries d WHERE d.delivery_id = OLD.delivery_id;
    SELECT oi.product_id INTO p FROM Order_Items oi WHERE oi.id = OLD.order_item_id;
    UPDATE Inventory SET quantity = quantity - OLD.quantity_delivered, last_updated = CURRENT_DATE
      WHERE store_id = s AND product_id = p;

    -- apply new
    SELECT d.store_id INTO s FROM Deliveries d WHERE d.delivery_id = NEW.delivery_id;
    SELECT oi.product_id INTO p FROM Order_Items oi WHERE oi.id = NEW.order_item_id;
    UPDATE Inventory SET quantity = quantity + NEW.quantity_delivered, last_updated = CURRENT_DATE
      WHERE store_id = s AND product_id = p;
    IF NOT FOUND THEN
      INSERT INTO Inventory (store_id, product_id, quantity, last_updated)
      VALUES (s, p, NEW.quantity_delivered, CURRENT_DATE);
    END IF;
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_delivery_items_inv ON Delivery_Items;
CREATE TRIGGER trg_delivery_items_inv
AFTER INSERT OR UPDATE OR DELETE ON Delivery_Items
FOR EACH ROW EXECUTE FUNCTION inv_on_delivery_items();
