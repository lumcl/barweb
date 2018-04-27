class IebSeqsController < ApplicationController
  before_action :set_ieb_seq, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @ieb_seqs = IebSeq.all
    respond_with(@ieb_seqs)
  end

  def show
    respond_with(@ieb_seq)
  end

  def new
    @ieb_seq = IebSeq.new
    respond_with(@ieb_seq)
  end

  def edit
  end

  def create
    @ieb_seq = IebSeq.new(ieb_seq_params)
    @ieb_seq.save
    respond_with(@ieb_seq)
  end

  def update
    @ieb_seq.update(ieb_seq_params)
    respond_with(@ieb_seq)
  end

  def destroy
    @ieb_seq.destroy
    respond_with(@ieb_seq)
  end

  private
    def set_ieb_seq
      @ieb_seq = IebSeq.find(params[:id])
    end

    def ieb_seq_params
      params.require(:ieb_seq).permit(:seq, :lastval)
    end
end
