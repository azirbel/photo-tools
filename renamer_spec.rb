require './renamer'

RSpec.describe DatePieces do
  describe '#initialize' do
    it 'works' do
      d = DatePieces.new('2001-02-03 04:05:06 -0700')

      expect(d.year).to eq('2001')
      expect(d.month).to eq('02')
      expect(d.day).to eq('03')
      expect(d.hour).to eq('04')
      expect(d.min).to eq('05')
      expect(d.sec).to eq('06')
    end
  end
end

RSpec.describe Renamer do
  describe '#initialize' do
    let(:renamer) { Renamer.new('input-folder') }

    it 'generates an output folder name' do
      expect(renamer.output_folder).to eq('input-folder-new')
    end

    it 'handles one conflict' do
      expect(File).to receive(:exist?)
        .with('input-folder-new')
        .and_return(true)

      expect(File).to receive(:exist?)
        .with('input-folder-new-a')
        .and_return(false)

      expect(renamer.output_folder).to eq('input-folder-new-a')
    end

    it 'handles two conflicts' do
      expect(File).to receive(:exist?)
        .with('input-folder-new')
        .and_return(true)

      expect(File).to receive(:exist?)
        .with('input-folder-new-a')
        .and_return(true)

      expect(File).to receive(:exist?)
        .with('input-folder-new-b')
        .and_return(false)

      expect(renamer.output_folder).to eq('input-folder-new-b')
    end
  end

  describe '#generate_new_filepath' do
    let(:renamer) { Renamer.new('input-folder') }
    let(:plan) { {} }
    let(:date_string) { '2001-02-03 04:05:06 -0700' }

    it 'works' do
      expect(
        renamer.generate_new_filepath('in.jpg', date_string, plan)
      ).to eq('input-folder-new/IMG_20010203_040506.jpg')
    end

    context 'with one conflict' do
      let(:plan) { { 'in.jpg': 'input-folder-new/IMG_20010203_040506.jpg' } }

      it 'works' do
        expect(
          renamer.generate_new_filepath('in.jpg', date_string, plan)
        ).to eq('input-folder-new/IMG_20010203_040506a.jpg')
      end
    end

    context 'with two conflicts' do
      let(:plan) { {
        'one.jpg': 'input-folder-new/IMG_20010203_040506.jpg',
        'two.jpg': 'input-folder-new/IMG_20010203_040506a.jpg',
      } }

      it 'works' do
        expect(
          renamer.generate_new_filepath('in.jpg', date_string, plan)
        ).to eq('input-folder-new/IMG_20010203_040506b.jpg')
      end
    end

    context 'with a suffix' do
      let(:renamer) { Renamer.new('input-folder', { suffix: 'yolo' }) }

      it 'works' do
        expect(
          renamer.generate_new_filepath('in.jpg', date_string, plan)
        ).to eq('input-folder-new/IMG_20010203_040506_yolo.jpg')
      end

      context 'with a non-conflict' do
        let(:plan) { { 'in.jpg': 'input-folder-new/IMG_20010203_040506.jpg' } }

        it 'works' do
          expect(
            renamer.generate_new_filepath('in.jpg', date_string, plan)
          ).to eq('input-folder-new/IMG_20010203_040506_yolo.jpg')
        end
      end

      context 'with one conflict' do
        let(:plan) { { 'in.jpg': 'input-folder-new/IMG_20010203_040506_yolo.jpg' } }

        it 'works' do
          expect(
            renamer.generate_new_filepath('in.jpg', date_string, plan)
          ).to eq('input-folder-new/IMG_20010203_040506a_yolo.jpg')
        end
      end
    end

    context 'with month folders' do
      let(:renamer) { Renamer.new('input-folder', { create_month_folders: true }) }

      it 'works' do
        expect(
          renamer.generate_new_filepath('in.jpg', date_string, plan)
        ).to eq('input-folder-new/2001_02/IMG_20010203_040506.jpg')
      end
    end
  end

  describe '#make_rename_plan' do
    let(:renamer) { Renamer.new('input-folder') }
    let(:files_with_dates) {
      {
        '1.jpg' => '2001-02-03 04:05:06 -0700',
        '2.jpg' => '2111-22-33 44:55:66 -0700',
        '3.jpg' => '2111-22-33 44:55:66 -0700',
      }
    }

    it 'works' do
      plan = renamer.make_rename_plan(files_with_dates)
      expected = {
        '1.jpg' => 'input-folder-new/IMG_20010203_040506.jpg',
        '2.jpg' => 'input-folder-new/IMG_21112233_445566.jpg',
        '3.jpg' => 'input-folder-new/IMG_21112233_445566a.jpg'
      }

      expect(plan).to eq(expected)
    end

    context 'with month folders' do
      let(:renamer) { Renamer.new('input-folder', { create_month_folders: true }) }

      it 'works' do
        plan = renamer.make_rename_plan(files_with_dates)
        expected = {
          '1.jpg' => 'input-folder-new/2001_02/IMG_20010203_040506.jpg',
          '2.jpg' => 'input-folder-new/2111_22/IMG_21112233_445566.jpg',
          '3.jpg' => 'input-folder-new/2111_22/IMG_21112233_445566a.jpg'
        }

        expect(plan).to eq(expected)
      end
    end

    context 'with missing EXIF data' do
      let(:files_with_dates) {
        {
          '1.jpg' => '2001-02-03 04:05:06 -0700',
          '2.jpg' => '2111-22-33 44:55:66 -0700',
          '3.jpg' => nil
        }
      }

      it 'works' do
        plan = renamer.make_rename_plan(files_with_dates)
        expected = {
          '1.jpg' => 'input-folder-new/IMG_20010203_040506.jpg',
          '2.jpg' => 'input-folder-new/IMG_21112233_445566.jpg',
          '3.jpg' => 'input-folder-new/missing-exif-data/3.jpg'
        }

        expect(plan).to eq(expected)
      end

      context 'with month folders' do
        let(:renamer) { Renamer.new('input-folder', { create_month_folders: true }) }

        it 'works' do
          plan = renamer.make_rename_plan(files_with_dates)
          expected = {
            '1.jpg' => 'input-folder-new/2001_02/IMG_20010203_040506.jpg',
            '2.jpg' => 'input-folder-new/2111_22/IMG_21112233_445566.jpg',
            '3.jpg' => 'input-folder-new/missing-exif-data/3.jpg'
          }

          expect(plan).to eq(expected)
        end
      end
    end
  end
end
