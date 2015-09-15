class CopyCodeReviewController < ApplicationController
  def create
    code_review = CodeReview.find(params[:code_review][:id])
    copy_code_review = code_review.duplicate_code_review_and_objectives(current_cohort)
    if copy_code_review.save
      flash[:notice] = "Code review successfully copied."
      redirect_to cohort_code_reviews_path(current_cohort)
    else
      flash[:alert] = "Code review not copied."
      redirect_to cohort_code_reviews_path(current_cohort)
    end
  end
end
