echo "Downloading .csv files from Kaggle"
files_to_download=$(kaggle competitions files h-and-m-personalized-fashion-recommendations --csv | grep csv | cut -d ',' -f1)
for file_to_download in $files_to_download
do
    kaggle competitions download \
        -c h-and-m-personalized-fashion-recommendations \
        -f $file_to_download \
        -p kaggle_raw_data
done

echo "Unzip files from Kaggle"
unzip -o -d kaggle_raw_data 'kaggle_raw_data/*.zip'
rm kaggle_raw_data/*.zip

echo "Upload files to GCS"
gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
gsutil mb -l $GCP_LOCATION -p $GCP_PROJECT_ID gs://$GCS_BUCKET
gsutil -m cp -n kaggle_raw_data/*.csv gs://$GCS_BUCKET

echo "Clean up locally"
rm -rf kaggle_raw_data

echo "Load files from GCS to BQ"
bq --location=$GCP_LOCATION mk -d \
    --project_id=$GCP_PROJECT_ID \
    --description "Kaggle H&M Personalized Fashion Recommendations: https://www.kaggle.com/c/h-and-m-personalized-fashion-recommendations/data" \
    $BQ_DATASET_ID

for file_path in $(ls kaggle_raw_data/*.csv)
do
    file=`basename "$file_path"`
    table_name="${file%.*}"
    echo $table_name
    bq load \
        --location=$GCP_LOCATION \
        --project_id=$GCP_PROJECT_ID \
        --dataset_id=$BQ_DATASET_ID \
        --source_format=CSV \
        --autodetect \
        $table_name \
        gs://$GCS_BUCKET/$file
done

echo "Data load to BQ has finished."
