class CsvImportsController < ApplicationController
    def new
      @csv_import = CsvImport.new
    end
  
    def create
      @csv_import = CsvImport.new(csv_import_params)
      
      if @csv_import.save
        @csv_import.process_import
        redirect_to @csv_import, notice: 'インポートを開始しました'
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
  