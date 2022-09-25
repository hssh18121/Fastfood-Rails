class ProductsController < ApplicationController

  before_action :require_user, except: [:show, :index, :search, :filter]
  before_action :require_admin, except: [:show, :index, :add_to_cart, :remove_from_cart, :checkout, :new_checkout, :add_quantity, :subtract_quantity, :add_to_favourite, :remove_from_favourite]
  def add_to_cart
    id = params[:id].to_i
    session[:cart] << id unless session[:cart].include?(id)
    redirect_to products_path
    @product_checkout_detail = ProductCheckoutDetail.new
    @product_checkout_detail.name = Product.find(id).name
    @product_checkout_detail.price = Product.find(id).price
    @product_checkout_detail.quantity = 1
    @product_checkout_detail.save
  end

  def remove_from_cart
    id = params[:id].to_i
    session[:cart].delete(id)
    @product_checkout_detail = ProductCheckoutDetail.find_by(name: Product.find(id).name)
    @product_checkout_detail.destroy
    redirect_to products_path
  end

  def cart
    @product_checkout_details = ProductCheckoutDetail.all
  end

  def add_quantity
    id = params[:id].to_i
    @product_checkout_detail = ProductCheckoutDetail.find_by(id: id)
    @product_checkout_detail.quantity += 1
    @product_checkout_detail.save
    redirect_to cart_path
  end

  def subtract_quantity

    id = params[:id].to_i
    @product_checkout_detail = ProductCheckoutDetail.find_by(id: id)
    @product_checkout_detail.quantity -= 1
    @product_checkout_detail.save
    redirect_to cart_path
  end

  def checkout
      @product_checkout_details = ProductCheckoutDetail.all
      total = 0
    if @product_checkout_details.present?
      @product_checkout_details.each do |product_checkout_detail|
        product_checkout_detail.save
        total = product_checkout_detail.price * product_checkout_detail.quantity + total
      end
      puts total
      session[:cart] = nil
      ProductCheckoutDetail.delete_all
      redirect_to checkout_path
    end
  end

  def new_checkout
    @r = Receipts::Receipt.new(

      details: [
        ["Receipt Number", "123"],
        ["Date paid", Date.today],
        ["Payment method", "ACH super long super long super long super long super long"]
      ],
      company: {
        name: "Example, LLC",
        address: "123 Fake Street\nNew York City, NY 10012",
        email: "support@example.com",

      },
      recipient: [
        "Customer",
        "Their Address",
        "City, State Zipcode",
        nil,
        "customer@example.org"
      ],

        line_items: [
          ["<b>Item</b>", "<b>Unit Cost</b>", "<b>Quantity</b>", "<b>Amount</b>"],
          ["Some random name", "$19.00", "1", "$19.00"],
          [nil, nil, "Subtotal", "$19.00"],
          [nil, nil, "Tax", "$1.12"],
          [nil, nil, "Total", "$20.12"],
          [nil, nil, "<b>Amount paid</b>", "$20.12"],
          [nil, nil, "Refunded on #{Date.today}", "$5.00"]
        ],

      footer: "Thanks for your business. Please contact us if you have any questions."
    )
    respond_to do |format|
      format.html
      format.json
      format.pdf{send_data @r.render, disposition: :inline}
    end
  end
  # GET /products or /products.json
  def index
    @products = Product.all
    @product_checkout_details = ProductCheckoutDetail.all
  end

  def search
    @products = Product.where("name LIKE ?", "%" + params[:q] + "%")
  end

  def sort
    if params[:value].to_i == 1
      @products = Product.order(:price)
    elsif params[:value].to_i == 2
      @products = Product.order(price: :desc)
    end
  end
  # GET /products/1 or /products/1.json
  def show
    @product = Product.find(params[:id])
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
    @product = Product.find(params[:id])
  end

  # POST /products or /products.json
  def create
    @product = Product.new(product_params)

    respond_to do |format|
      if @product.save
        format.html { redirect_to product_url(@product), notice: "Product was successfully created." }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1 or /products/1.json
  def update
    @product = Product.find(params[:id])
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to product_url(@product), notice: "Product was successfully updated." }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1 or /products/1.json
  def destroy
    @product = Product.find(params[:id])
    @product.destroy

    respond_to do |format|
      format.html { redirect_to products_url, notice: "Product was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def add_to_favourite
    @favourite_manager = FavouriteManager.new
    @favourite_manager.user_id = current_user.id
    id = params[:id].to_i
    @favourite_manager.product_id = id
    @favourite_manager.save
    respond_to do |format|
      format.js {render inline: "location.reload();"}
    end
  end

  def remove_from_favourite
    id = params[:id].to_i
    @favourite_manager = FavouriteManager.find_by(user_id: current_user.id, product_id: id)
    @favourite_manager.destroy

    respond_to do |format|
      format.js {render inline: "location.reload();"}
    end
  end

  def favourites
    @favourite_managers = FavouriteManager.all
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])

    end

    # Only allow a list of trusted parameters through.
    def product_params
      params.require(:product).permit(:name, :description, :price, :image, :category_id)
    end






end
