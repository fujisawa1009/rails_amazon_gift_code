class CsvImportsController < ApplicationController
    def new
      @csv_import = CsvImport.new
    end
  
    def create
      @csv_import = CsvImport.new(csv_import_params)
      @csv_import.status = 0  # または 'pending' 状態で設定
      
      if @csv_import.save
        @csv_import.process_import
        redirect_to root_path, notice: 'CSVインポートを開始しました'  # root_pathにリダイレクト
      else
        render :new
      end
    end
  
    def show
      @csv_import = CsvImport.find(params[:id])
    end
  
    private
  
    def csv_import_params
      params.require(:csv_import).permit(:file)
    end
  end
  