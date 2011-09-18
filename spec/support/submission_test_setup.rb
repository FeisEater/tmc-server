require File.expand_path(File.join(File.dirname(__FILE__), 'git_test_actions.rb'))

# Aggregates everything needed to test checking a submission
class SubmissionTestSetup
  include GitTestActions

  attr_reader :course
  attr_reader :repo
  attr_reader :exercise
  attr_reader :exercise_project
  attr_reader :user
  attr_reader :submission

  def initialize(options = {})
    options = default_options.merge(options)
    
    course_name = options[:course_name]
    exercise_name = options[:exercise_name] || 'SimpleExercise'
    exercise_dest = options[:exercise_dest] || exercise_name
    should_solve = options[:solve]
    should_save = options[:save]
    @user = options[:user] || create_user
    
    @course = Course.create!(:name => course_name)
    @repo = clone_course_repo(@course)
    @repo.copy_fixture_exercise(exercise_name, exercise_dest)
    @repo.add_commit_push
    @course.refresh
    
    @exercise = @course.exercises.first
    
    if exercise_name == 'SimpleExercise'
      @exercise_project = SimpleExercise.new(exercise_dest)
    else
      @exercise_project = FixtureExercise.new(exercise_name, exercise_dest)
    end
    
    @submission = Submission.new(
      :user => @user,
      :course => @course,
      :exercise => @exercise,
      :return_file_tmp_path => exercise_dest + ".zip"
    )
    
    if should_solve
      @exercise_project.solve_all
    end
    
    if should_save
      make_zip
      @submission.save!
    end
  end
  
  def make_zip
    @exercise_project.make_zip
  end
  
  def default_options
    {
      :course_name => 'MyCourse',
      :exercise_name => nil,
      :exercise_dest => nil,
      :user => nil,
      :solve => false,
      :save => false
    }
  end
  
private
  def create_user
    User.create!(:login => 'student', :password => 'student')
  end
end