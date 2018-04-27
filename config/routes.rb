Rails.application.routes.draw do
  resources :pcbmains

  resources :qacodes do
    collection do
      get 'read_sony_cycle'
      get 'process_sony_cycle'
      get 'get_product_order'
      get 'show_material_issue'
      get 'query'
      post 'query'
    end
  end

  resources :prodrules

  resources :qrcodes do
    collection do
      get 'read_barcode'
      get 'process_barcode'
      get 'read_barcode_repeat'
      get 'process_barcode_repeat'
      get 'read_barcode_rule'
      get 'process_barcode_rule'
      get 'read_barcode_sony_cycle'
      get 'process_barcode_sony_cycle'
      get 'get_product_order'
      get 'get_product_order_repeat'
      get 'show_material_issue'
    end
  end

  resources :qbarcodes do
      collection do
        get 'read_barcode'
        get 'process_barcode'
        get 'read_barcode_repeat'
        get 'process_barcode_repeat'
        get 'get_product_order'
        get 'get_product_order_repeat'
        get 'show_material_issue'
      end
    end

  resources :ieb_erp_stocks

  resources :ieb_mrp_exg_moves

  resources :v_dec_bill_lists

  resources :ieb_seqs

  namespace :zmm do
    resources :item_suppliers
  end

  namespace :zieb do
    resources :import_order_lines
    resources :import_orders do
      collection do
        post 'to_excel'
      end
      member do
        post 'create_zieb_import_order_lines'
        get 'display_add_detail_selection_form'
        get 'paste_purchase_order_line'
        post 'paste_purchase_order_line'
        post 'create_zieb_import_order_lines_by_po_lines'
        get 'packing_list'
        get 'invoice'
      end
    end
  end

  resources :ieb_msegs do
    collection do
      get 'zindex_v3'
      post 'zcreate_v3'
    end
  end

  resources :ieb_ziebe001s do
    collection do
      post 'upload_ygt'
    end
  end

  resources :ieb_ziebi001s do
    collection do
      post 'upload_ygt'
    end
  end

  resources :ieb_zieba003s do
    collection do
      post 'upload_ygt'
    end
  end

  resources :ieb_ziebc001s do
    collection do
      post 'upload_ygt'
    end
  end

  resources :sap_se16ns

  resources :ieb_bom_lines

  resources :ieb_boms do
    collection do
      get 'version_matrix'
      post 'upload_bom_to_ygt'
    end
  end

  resources :ieb_afpos do
    collection do
      post 'calculate_bom'
    end
  end

  devise_for :users

  root 'dashboard#index'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
